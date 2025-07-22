# 🎯 Internship Matching Contract

A decentralized smart contract platform for matching internship applicants with employers based on reputation and availability.

## 🌟 Features

- **👥 Dual Registration**: Separate registration for applicants and employers
- **⭐ Reputation System**: Track and update reputation scores for both parties  
- **🔄 Availability Management**: Real-time availability tracking
- **🤝 Smart Matching**: Match applicants to internships based on reputation thresholds
- **📊 Performance Ratings**: Mutual rating system after internship completion
- **🔐 Secure Transactions**: Blockchain-based verification and tracking

## 🚀 Quick Start

### For Applicants

1. **Register as an applicant**
   ```clarity
   (contract-call? .internship-matching-contract register-applicant "John Doe" "JavaScript, React, Node.js")
   ```

2. **Apply for internships**
   ```clarity
   (contract-call? .internship-matching-contract apply-for-internship u1)
   ```

3. **Manage availability**
   ```clarity
   (contract-call? .internship-matching-contract set-availability true)
   ```

### For Employers

1. **Register as an employer**
   ```clarity
   (contract-call? .internship-matching-contract register-employer "TechCorp Inc" "Software Development")
   ```

2. **Create internship opportunities**
   ```clarity
   (contract-call? .internship-matching-contract create-internship 
     "Frontend Developer Intern" 
     "Work with React and modern web technologies"
     "JavaScript, HTML, CSS knowledge required"
     u12  ; 12 weeks duration
     u1000) ; stipend amount
   ```

3. **Match with applicants**
   ```clarity
   (contract-call? .internship-matching-contract create-match u1 u1) ; applicant-id, internship-id
   ```

## 📋 Contract Functions

### 📝 Registration Functions
- `register-applicant(name, skills)` - Register as an applicant
- `register-employer(company, industry)` - Register as an employer

### 🏢 Internship Management
- `create-internship(title, description, requirements, duration, stipend)` - Create new internship
- `apply-for-internship(internship-id)` - Apply for an internship

### 🔗 Matching System
- `create-match(applicant-id, internship-id)` - Create a match between applicant and internship
- `start-internship(match-id)` - Start the internship
- `complete-internship(match-id)` - Mark internship as completed

### ⭐ Rating & Reputation
- `rate-participant(match-id, rating, target)` - Rate the other party (1-5 stars)
- Reputation automatically updates based on ratings

### 🔧 Status Management
- `set-availability(available)` - Update applicant availability
- `set-employer-status(active)` - Update employer active status

## 📊 Data Structures

### Applicant Profile
- Wallet address
- Name and skills
- Reputation score (starts at 50)
- Availability status
- Registration timestamp

### Employer Profile  
- Wallet address
- Company name and industry
- Reputation score (starts at 50)
- Active status
- Registration timestamp

### Internship Listing
- Employer details
- Title, description, requirements
- Duration and stipend
- Status (open/matched)
- Creation timestamp

### Match Record
- Applicant and employer IDs
- Internship details
- Status tracking
- Completion timestamp
- Mutual ratings

## 🛡️ Reputation System

- **Starting Score**: 50 points for new users
- **Good Performance** (4-5 star rating): +5 reputation
- **Poor Performance** (1-3 star rating): -5 reputation
- **Minimum Reputation**: 30 points required to participate

## ⚠️ Requirements

- **Clarinet**: For contract development and testing
- **Stacks Blockchain**: For deployment
- **Minimum Reputation**: 30 points to apply for internships

## 🔍 Read-Only Functions

- `get-applicant(applicant-id)` - Get applicant details
- `get-employer(employer-id)` - Get employer details
- `get-internship(internship-id)` - Get internship details
- `get-match(match-id)` - Get match details
- `get-applicant-by-wallet(wallet)` - Find applicant by wallet
- `get-employer-by-wallet(wallet)` - Find employer by wallet

## 🚦 Error Codes

| Code | Description |
|------|-------------|
| 100  | Unauthorized access |
| 101  | Resource not found |
| 102  | Resource already exists |
| 103  | Invalid status |
| 104  | Invalid parameters |
| 105  | Insufficient reputation |
| 106  | Not available |
| 107  | Already matched |

## 🧪 Testing

Run the contract checker:
```bash
clarinet check
```

Run tests:
```bash
npm install
npm test
```

## 💡 Usage Examples

### Complete Workflow Example

1. **Alice registers as an applicant**
2. **TechCorp registers as an employer**  
3. **TechCorp creates a frontend internship**
4. **Alice applies for the internship**
5. **TechCorp matches Alice to the internship**
6. **Both parties start the internship**
7. **After completion, both rate each other**
8. **Reputation scores update automatically**

### Rating System Example
```clarity
;; Employer rates applicant 5 stars (excellent work)
(contract-call? .internship-matching-contract rate-participant u1 u5 "applicant")

;; Applicant rates employer 4 stars (good experience)  
(contract-call? .internship-matching-contract rate-participant u1 u4 "employer")
```

## 🎯 Benefits

- **🔒 Trustless**: No central authority needed
- **📈 Merit-Based**: Reputation drives opportunities
- **🌐 Transparent**: All transactions on blockchain
- **💰 Cost-Effective**: Minimal transaction fees
- **🔄 Self-Improving**: System gets better with usage

---

*Built with ❤️ using Clarity smart contracts on Stacks blockchain*
