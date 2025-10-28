import "FungibleToken"
import "FlowToken"
import "TrixyTypes"
import "TrixyEvents"
import "DeFiActions"
import "FungibleTokenConnectors"

access(all) contract Market {
    
    access(all) resource MarketResource {
        access(all) let id: UInt64
        access(all) let question: String
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64
        access(all) let options: [String] 
        access(all) let yieldProtocol: String 
        access(all) let creator: Address
        
        access(all) var status: TrixyTypes.MarketStatus
        access(all) var winningOption: String? 
        
        access(self) let vault: @FlowToken.Vault
        
        access(self) let optionStats: {String: TrixyTypes.ProtocolStats}
        
        access(self) let userPositions: {Address: [TrixyTypes.UserPosition]}
        
        access(self) let yieldVault: @FlowToken.Vault
        access(all) var totalYieldEarned: UFix64
        
        access(self) var yieldVaultSource: {DeFiActions.Source}?
        access(self) var yieldVaultSink: {DeFiActions.Sink}?
        
        init(
            id: UInt64,
            question: String,
            endTime: UFix64,
            options: [String],
            yieldProtocol: String,
            creator: Address,
            protocolFee: UFix64
        ) {
            pre {
                options.length >= 2: "Must have at least 2 options"
                options.length <= 10: "Maximum 10 options allowed"
                endTime > getCurrentBlock().timestamp: "End time must be in future"
                yieldProtocol == "ankr" || yieldProtocol == "increment" || yieldProtocol == "figment": "Invalid yield protocol"
            }
            
            self.id = id
            self.question = question
            self.startTime = getCurrentBlock().timestamp
            self.endTime = endTime
            self.options = options
            self.yieldProtocol = yieldProtocol
            self.creator = creator
            self.status = TrixyTypes.MarketStatus.Active
            self.winningOption = nil
            
            self.vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            self.yieldVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            self.optionStats = {}
            self.userPositions = {}
            self.totalYieldEarned = 0.0
            
            self.yieldVaultSource = nil
            self.yieldVaultSink = nil
            
            
            for option in options {
                self.optionStats[option] = TrixyTypes.ProtocolStats(name: option, protocolType: TrixyTypes.ProtocolType.Increment)
            }
        }
        
        access(all) fun placeBet(user: Address, option: String, payment: @FlowToken.Vault, protocolFee: UFix64) {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Market not active"
                getCurrentBlock().timestamp < self.endTime: "Market ended"
                self.options.contains(option): "Invalid option"
                payment.balance > 0.0: "Amount must be > 0"
            }
            
            let amount = payment.balance
            let feeAmount = amount * protocolFee
            let netAmount = amount - feeAmount
            
            
            if feeAmount > 0.0 {
                let fee <- payment.withdraw(amount: feeAmount) as! @FlowToken.Vault
                destroy fee
            }
            
            self.vault.deposit(from: <- payment)
            
            let newPosition = TrixyTypes.UserPosition(protocol: option, amount: netAmount)
            if self.userPositions[user] == nil {
                self.userPositions[user] = [newPosition]
            } else {
                self.userPositions[user]!.append(newPosition)
            }
            
            self.optionStats[option]!.updateStake(amount: netAmount)
            
            self.depositToYieldProtocol(amount: netAmount)
            
            TrixyEvents.emitBetPlaced(marketId: self.id, user: user, selectedOption: option, amount: netAmount)
        }
        
        access(all) fun setupFlowActionsConnectors(
            vaultCap: Capability<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>,
            maxBalance: UFix64?
        ) {
            pre {
                vaultCap.check(): "Invalid vault capability"
                self.yieldVaultSource == nil: "Connectors already configured"
            }
            
            self.yieldVaultSource = FungibleTokenConnectors.VaultSource(
                min: 0.0,
                withdrawVault: vaultCap,
                uniqueID: nil
            )
            
            self.yieldVaultSink = FungibleTokenConnectors.VaultSink(
                max: maxBalance,
                depositVault: vaultCap,
                uniqueID: nil
            )
        }
        
        access(self) fun depositToYieldProtocol(amount: UFix64) {
            let funds <- self.vault.withdraw(amount: amount) as! @FlowToken.Vault
            
            if let sink = self.yieldVaultSink {
                sink.depositCapacity(from: &funds as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
            }
            
            self.yieldVault.deposit(from: <- funds)
            
            TrixyEvents.emitYieldDeposited(marketId: self.id, protocol: self.yieldProtocol, amount: amount)
        }
        
        access(all) fun resolveMarket(winningOption: String) {
            pre {
                self.status == TrixyTypes.MarketStatus.Active: "Market already resolved"
                getCurrentBlock().timestamp >= self.endTime: "Market not ended"
                self.options.contains(winningOption): "Invalid winning option"
            }
            
            self.status = TrixyTypes.MarketStatus.Resolved
            self.winningOption = winningOption
            
            
            self.withdrawAllYield()
            
            let protocolAPYs: {String: UFix64} = {}
            protocolAPYs[winningOption] = 0.0
            
            TrixyEvents.emitMarketResolved(marketId: self.id, winningOption: winningOption, apys: protocolAPYs)
        }
        
        access(self) fun withdrawAllYield() {
            let balance = self.yieldVault.balance
            
            if balance > 0.0 {
                var totalStaked = 0.0
                for option in self.options {
                    totalStaked = totalStaked + self.optionStats[option]!.totalStaked
                }
                
                let yieldEarned = balance > totalStaked ? balance - totalStaked : 0.0
                self.totalYieldEarned = yieldEarned
                
                let withdrawn <- self.yieldVault.withdraw(amount: balance)
                self.vault.deposit(from: <- withdrawn)
                
                TrixyEvents.emitYieldWithdrawn(
                    marketId: self.id, 
                    protocol: self.yieldProtocol, 
                    amount: balance, 
                    yieldEarned: yieldEarned
                )
            }
        }
        
        access(all) fun claimWinnings(user: Address): @FlowToken.Vault {
            pre {
                self.status == TrixyTypes.MarketStatus.Resolved: "Market not resolved"
                self.userPositions[user] != nil: "No position found"
                self.userPositions[user]!.length > 0: "No positions found"
            }
            
            let positions = self.userPositions[user]!
            var totalPayout = 0.0
            let updatedPositions: [TrixyTypes.UserPosition] = []
            
            for position in positions {
                if !position.claimed {
                    let payout = self.calculatePayout(position: position)
                    totalPayout = totalPayout + payout
                    
                    let updatedPosition = TrixyTypes.UserPosition(protocol: position.protocol, amount: position.amount)
                    updatedPosition.setClaimed()
                    updatedPosition.setYield(amount: payout - position.amount)
                    updatedPositions.append(updatedPosition)
                } else {
                    updatedPositions.append(position)
                }
            }
            
            self.userPositions[user] = updatedPositions
            
            TrixyEvents.emitWinningsClaimed(marketId: self.id, user: user, payout: totalPayout)
            
            return <- self.vault.withdraw(amount: totalPayout) as! @FlowToken.Vault
        }
        
        access(self) fun calculatePayout(position: TrixyTypes.UserPosition): UFix64 {
            let isWinner = position.protocol == self.winningOption
            var payout = 0.0
            
            if isWinner {
                let winningStats = self.optionStats[self.winningOption!]!
                let userShare = position.amount / winningStats.totalStaked
                
                
                payout = position.amount
                payout = payout + (self.totalYieldEarned * userShare)
                
                var totalLosingStakes = 0.0
                for option in self.options {
                    if option != self.winningOption {
                        totalLosingStakes = totalLosingStakes + self.optionStats[option]!.totalStaked
                    }
                }
                
                payout = payout + (totalLosingStakes * userShare)
            } else {
                
                payout = 0.0
            }
            
            return payout
        }
        
        access(all) fun getInfo(): TrixyTypes.MarketInfo {
            return TrixyTypes.MarketInfo(
                id: self.id,
                question: self.question,
                startTime: self.startTime,
                endTime: self.endTime,
                protocols: self.options,
                status: self.status,
                winningProtocol: self.winningOption,
                totalPool: self.vault.balance,
                protocolStats: self.optionStats,
                creator: self.creator
            )
        }
        
        access(all) fun getPositions(user: Address): [TrixyTypes.UserPosition]? {
            return self.userPositions[user]
        }
        
        access(all) fun getProtocolStats(option: String): TrixyTypes.ProtocolStats? {
            return self.optionStats[option]
        }
        
        access(all) fun getLeaderboard(): [TrixyTypes.ProtocolStats] {
            let stats: [TrixyTypes.ProtocolStats] = []
            for option in self.options {
                stats.append(self.optionStats[option]!)
            }
            return stats
        }
        
        access(all) fun getFlowActionsStatus(): {String: Bool} {
            return {
                "hasSource": self.yieldVaultSource != nil,
                "hasSink": self.yieldVaultSink != nil
            }
        }
    }
    
    access(all) fun createMarket(
        id: UInt64,
        question: String,
        endTime: UFix64,
        options: [String],
        yieldProtocol: String,
        creator: Address,
        protocolFee: UFix64
    ): @MarketResource {
        return <- create MarketResource(
            id: id,
            question: question,
            endTime: endTime,
            options: options,
            yieldProtocol: yieldProtocol,
            creator: creator,
            protocolFee: protocolFee
        )
    }
}
