# ♻️ Circular Economy Marketplace

A blockchain-powered marketplace that revolutionizes product lifecycle management by connecting consumers with manufacturers for seamless buyback and recycling of used goods through secure escrow contracts.

## 🌍 Overview

The Circular Economy Marketplace creates a sustainable ecosystem where:
- 🛍️ Consumers can list used products for manufacturer buyback
- 🏭 Manufacturers reclaim and recycle their products
- 💰 Escrow contracts ensure secure transactions
- 🎁 Recycling rewards incentivize participation
- 📊 Environmental impact is tracked and rewarded

## ✨ Key Features

### 🔐 Secure Escrow System
- Automated payment holding until condition verification
- Dispute resolution mechanisms
- Platform fee collection for sustainability

### 🏆 Recycling Rewards
- Fungible token rewards for successful recycling
- Condition-based reward multipliers
- Category-specific incentives

### 👥 Multi-Role Support
- **Consumers**: List and sell used products
- **Manufacturers**: Register, verify, and buy back products
- **Platform Admin**: Resolve disputes and manage system

### 📈 Comprehensive Metrics
- User reputation scoring
- Manufacturer sustainability tracking
- Platform-wide recycling statistics
- Environmental impact measurement

## 🚀 Quick Start

### 1. Register as Manufacturer

```clarity
(contract-call? .Circular-Economy-Marketplace register-manufacturer "EcoTech Industries")
```

### 2. Verify Manufacturer (Admin Only)

```clarity
(contract-call? .Circular-Economy-Marketplace verify-manufacturer 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### 3. List a Product for Buyback

```clarity
(contract-call? .Circular-Economy-Marketplace list-product
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; manufacturer
    "iPhone 12 Pro"                               ;; product name
    "electronics"                                  ;; category
    u100                                          ;; original purchase date (block)
    u4                                            ;; condition (1-5, 5 = excellent)
    u1000000000)                                  ;; original price in microSTX
```

### 4. Initiate Buyback (Manufacturer)

```clarity
(contract-call? .Circular-Economy-Marketplace initiate-buyback u1)  ;; listing-id
```

### 5. Confirm Product Condition (Manufacturer)

```clarity
(contract-call? .Circular-Economy-Marketplace confirm-condition u1 true)  ;; escrow-id, condition-met
```

### 6. Release Payment

```clarity
(contract-call? .Circular-Economy-Marketplace release-payment u1)  ;; escrow-id
```

## 📊 Product Conditions

| Level | Name | Buyback % | Description |
|-------|------|-----------|-------------|
| 5 | Excellent | 70% | Like new, minimal wear |
| 4 | Good | 50% | Light wear, fully functional |
| 3 | Fair | 30% | Moderate wear, functional |
| 2 | Poor | 15% | Heavy wear, limited function |
| 1 | Broken | 5% | For parts/recycling only |

## 💎 Recycling Rewards

Rewards are calculated based on:
- Product condition (higher condition = more rewards)
- Product category multiplier
- Base reward rate (1000 tokens)

Formula: `base * category_multiplier * condition_bonus / 1000`

## 🔍 Read Functions

### Get Listing Details
```clarity
(contract-call? .Circular-Economy-Marketplace get-listing u1)
```

### Check Escrow Status
```clarity
(contract-call? .Circular-Economy-Marketplace get-escrow u1)
```

### View User Metrics
```clarity
(contract-call? .Circular-Economy-Marketplace get-user-metrics 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Platform Statistics
```clarity
(contract-call? .Circular-Economy-Marketplace get-platform-stats)
```

### Check Reward Balance
```clarity
(contract-call? .Circular-Economy-Marketplace get-recycling-reward-balance 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Calculate Buyback Price
```clarity
(contract-call? .Circular-Economy-Marketplace calculate-estimated-buyback u1000000000 u4)
```

## 🛡️ Dispute Resolution

If a dispute arises during the transaction:

1. **Raise Dispute**
```clarity
(contract-call? .Circular-Economy-Marketplace dispute-escrow u1 "Product condition worse than described")
```

2. **Admin Resolution**
```clarity
(contract-call? .Circular-Economy-Marketplace resolve-dispute u1 true)  ;; true = release to seller, false = refund buyer
```

## 📈 Platform Fees

- **Escrow Fee**: 2.5% of buyback price
- Collected automatically during buyback initiation
- Used for platform maintenance and development

## 🎯 Benefits

### For Consumers
- 💰 Get paid for used products
- 🏆 Earn recycling rewards
- 🌱 Contribute to sustainability
- ⭐ Build reputation score

### For Manufacturers
- ♻️ Reclaim products for recycling
- 📊 Track sustainability metrics
- 🔄 Close the product lifecycle loop
- 🏅 Improve brand image

### For the Environment
- 🌍 Reduce landfill waste
- 🔄 Promote circular economy
- 📉 Lower carbon footprint
- 🌿 Encourage sustainable consumption

## 🔐 Security Features

- Escrow-protected transactions
- Manufacturer verification system
- Dispute resolution mechanism
- Condition verification process
- Immutable transaction history

## 📊 Contract Statistics

- Total Functions: 16
- Public Functions: 10
- Read-Only Functions: 6
- Data Maps: 6
- Error Codes: 18
- Token Types: 1 (Recycling Rewards)

## 🛠️ Development

### Testing
```bash
clarinet test
```

### Console
```bash
clarinet console
```

### Check Contract
```bash
clarinet check
```

## 📝 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Operation restricted to contract owner |
| u103 | err-listing-not-found | Product listing doesn't exist |
| u104 | err-unauthorized | User not authorized for this operation |
| u107 | err-escrow-not-found | Escrow contract doesn't exist |
| u111 | err-invalid-condition | Invalid product condition (must be 1-5) |
| u116 | err-manufacturer-not-found | Manufacturer not registered |

## 🌟 Future Enhancements

- 🤝 Multi-signature escrow
- 📱 Mobile app integration
- 🏪 Marketplace for refurbished goods
- 🌐 Cross-chain compatibility
- 📊 Advanced analytics dashboard
- 🎨 NFT certificates for recycled items

## 🤝 Contributing

We welcome contributions! Please ensure all changes maintain the circular economy principles and include appropriate tests.

## 📄 License

This smart contract promotes sustainable practices and circular economy principles on the Stacks blockchain.

