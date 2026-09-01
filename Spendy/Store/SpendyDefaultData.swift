//
//  SpendyDefaultData.swift
//  Spendy
//
//  Pre-seeded user dataset containing accounts, custom folders, categories,
//  active subscriptions, budget goals, and normalized transactions.
//

import Foundation

enum SpendyDefaultData {
    static let userName: String = "Pavan"
    static let currencySymbol: String = "₹"
    static let currencyCode: String = "INR"
    static let appearanceMode: AppearanceMode = .dark
    static let topGradientColorHex: String = "#007AFF"
    static let topGradientHue: Double = 0.60
    static let topGradientBrightness: Double = 0.85
    static let isGradientBackgroundEnabled: Bool = true
    
    static let budget: Budget = Budget(
        amount: 20000.0,
        period: .monthly,
        startDay: 1,
        isActive: true,
        categoryBudgets: [:]
    )
    
    static let accounts: [Account] = [
        Account(id: "bank", label: "SBI", sfSymbol: "landmark.fill", colorHex: "#007AFF", openingBalance: 0.52, order: 0, type: .bank),
        Account(id: "bank2", label: "CANARA", sfSymbol: "landmark.fill", colorHex: "#FF9500", openingBalance: 2451.0, order: 1, type: .bank),
        Account(id: "cash", label: "Cash", sfSymbol: "dollarsign.square.fill", colorHex: "#30D158", openingBalance: 140.0, order: 2, type: .cash)
    ]
    
    static let customFolders: [Folder] = [
        Folder(id: "folder_family_expense", name: "Family", type: .expense),
        Folder(id: "folder_family_income", name: "Family", type: .income),
        Folder(id: "folder_wellness_income", name: "Personal & Wellness", type: .income)
    ]
    
    static let categories: [Category] = [
        Category(id: "paycheck", label: "Paycheck", sfSymbol: "banknote.fill", colorHex: "#30D158", type: .income, folder: "Salary & Career", isHidden: false, order: 0),
        Category(id: "freelance", label: "Freelance", sfSymbol: "laptopcomputer.and.iphone", colorHex: "#3478F6", type: .income, folder: "Salary & Career", isHidden: false, order: 1),
        Category(id: "investment", label: "Investment", sfSymbol: "piggybank.fill", colorHex: "#FFD60A", type: .income, folder: "Investments & Other", isHidden: false, order: 2),
        Category(id: "refund", label: "Refund", sfSymbol: "receipt", colorHex: "#FF9500", type: .income, folder: "Investments & Other", isHidden: false, order: 3),
        Category(id: "gift", label: "Gift", sfSymbol: "gift.circle.fill", colorHex: "#BF5AF2", type: .income, folder: "Personal & Wellness", isHidden: false, order: 4),
        Category(id: "appa_abf1da64-a521-42cf-93f8-f8856dbe92a9", label: "Appa", sfSymbol: "tag.fill", colorHex: "#30B0C7", type: .income, folder: "Family", isHidden: false, order: 5),
        Category(id: "stock_income_d8cfb65d-bab7-4c48-afae-28bbbfa93d14", label: "Stock income", sfSymbol: "chart.line.uptrend.xyaxis.circle.fill", colorHex: "#0300E8", type: .income, folder: "Investments & Other", isHidden: false, order: 6),
        Category(id: "amma_fbe39d49-fe39-4ee5-8ccc-8c3cbe1af1d7", label: "Amma", sfSymbol: "figure.2.and.child.holdinghands", colorHex: "#FFD60A", type: .income, folder: "Family", isHidden: false, order: 7),
        Category(id: "food", label: "Food", sfSymbol: "fork.knife.circle.fill", colorHex: "#3478F6", type: .expense, folder: "Everyday Spending", isHidden: false, order: 0),
        Category(id: "transport", label: "Fuel", sfSymbol: "fuelpump.circle.fill", colorHex: "#FFD60A", type: .expense, folder: "Transport", isHidden: false, order: 1),
        Category(id: "groceries", label: "Groceries", sfSymbol: "basket.fill", colorHex: "#03DBFF", type: .expense, folder: "Everyday Spending", isHidden: false, order: 2),
        Category(id: "entertainment", label: "Entertainment", sfSymbol: "popcorn.circle.fill", colorHex: "#FF453A", type: .expense, folder: "Personal & Wellness", isHidden: false, order: 3),
        Category(id: "savings", label: "Savings", sfSymbol: "piggybank.fill", colorHex: "#30D158", type: .expense, folder: "Living", isHidden: false, order: 4),
        Category(id: "subscriptions", label: "Subscriptions", sfSymbol: "receipt", colorHex: "#FF2D55", type: .expense, folder: "Living", isHidden: false, order: 5),
        Category(id: "amma_d88ec4dd-0186-4c31-860b-4314d1edd7d1", label: "Amma", sfSymbol: "leaf.fill", colorHex: "#DC07FF", type: .expense, folder: "Family", isHidden: false, order: 6),
        Category(id: "cat_d6049b7b-6a4b-4ed9-bfdd-297c067398e3", label: "Cat", sfSymbol: "pawprint.circle.fill", colorHex: "#FF6482", type: .expense, folder: "Personal & Wellness", isHidden: false, order: 7),
        Category(id: "appa_18058f26-bcc2-4437-9e03-6bd014966ca1", label: "Appa", sfSymbol: "building.2.crop.circle.fill", colorHex: "#A2FBFF", type: .expense, folder: "Family", isHidden: false, order: 8),
        Category(id: "amazon_pay_balance_cfe5c8cf-78c0-4877-8c71-a76a4a872541", label: "Amazon Pay Balance", sfSymbol: "cart.fill", colorHex: "#595CFF", type: .expense, folder: "Everyday Spending", isHidden: false, order: 9),
        Category(id: "haircut_0c840b17-b63d-4246-bdba-8bf571b521a8", label: "Haircut", sfSymbol: "scissors", colorHex: "#30B0C7", type: .expense, folder: "Personal & Wellness", isHidden: false, order: 10),
        Category(id: "parking_7ea8830e-000a-4f72-92d4-7a29be989330", label: "parking", sfSymbol: "car.side.fill", colorHex: "#30D158", type: .expense, folder: "Transport", isHidden: false, order: 11),
        Category(id: "help_6c2c738b-a421-48c0-9195-4385e0358432", label: "Help", sfSymbol: "heart.square.fill", colorHex: "#FF2D55", type: .expense, folder: "Personal & Wellness", isHidden: false, order: 12),
        Category(id: "extra_ac33f52e-2778-42ab-ba60-83151a701440", label: "Extra", sfSymbol: "handbag.fill", colorHex: "#FF375F", type: .expense, folder: "Personal & Wellness", isHidden: false, order: 13),
        Category(id: "essentials_1e661c95-fb48-4905-b1eb-4a761e2b3068", label: "Essentials", sfSymbol: "eyeglasses", colorHex: "#FF9500", type: .expense, folder: "Everyday Spending", isHidden: false, order: 14),
        Category(id: "stationary_9a2bcefa-171b-4bd8-92c7-307bf5528557", label: "Stationary", sfSymbol: "pencil.and.ruler.fill", colorHex: "#FF453A", type: .expense, folder: "Everyday Spending", isHidden: false, order: 15),
        Category(id: "lucky_chit_2c665d23-ad7a-495b-86f6-3305467e0d05", label: "Lucky Chit", sfSymbol: "creditcard.circle.fill", colorHex: "#30B0C7", type: .expense, folder: "Living", isHidden: false, order: 16),
        Category(id: "anc_9bc1f674-5662-47b6-803f-a1b1d93878e0", label: "ANC", sfSymbol: "creditcard.fill", colorHex: "#007AFF", type: .expense, folder: "Living", isHidden: false, order: 17),
        Category(id: "medicin_194cfec8-cd29-45f9-a9ab-00ee2a88b86c", label: "Medicine", sfSymbol: "cross.case.fill", colorHex: "#30D158", type: .expense, folder: "Personal & Wellness", isHidden: false, order: 18),
        Category(id: "travel_d8736db9-398b-4339-a4b3-7aa3b5ee55e0", label: "Travel", sfSymbol: "tram.fill", colorHex: "#BF5AF2", type: .expense, folder: "Transport", isHidden: false, order: 19),
    ]
    
    static let subscriptions: [Subscription] = [
        Subscription(
            id: UUID(uuidString: "E0C328A0-B6BD-4396-B32E-1E2ED7D6A7F5") ?? UUID(),
            name: "Apple Music",
            amount: 59.0,
            cycle: .monthly,
            nextBillingDate: ISO8601DateFormatter().date(from: "2026-09-01T00:00:00Z") ?? Date(),
            categoryId: "subscriptions",
            accountId: "bank",
            autoDeduct: false,
            isPaused: false,
            isTrial: false,
            status: "active",
            sfSymbol: "apple.logo",
            colorHex: "#FF2D55",
            isDarkBadge: true
        ),
        Subscription(
            id: UUID(uuidString: "46EA622C-211E-452F-AA26-8EA721FB7EF2") ?? UUID(),
            name: "Not Boring Weather",
            amount: 499.0,
            cycle: .yearly,
            nextBillingDate: ISO8601DateFormatter().date(from: "2026-11-26T00:00:00Z") ?? Date(),
            categoryId: "subscriptions",
            accountId: "bank",
            autoDeduct: false,
            isPaused: false,
            isTrial: false,
            status: "active",
            sfSymbol: "cloud.sun.fill",
            colorHex: "#FF9500",
            isDarkBadge: true
        ),
        Subscription(
            id: UUID(uuidString: "E1B78D4B-84FC-476D-8412-15706719828C") ?? UUID(),
            name: "Instagram",
            amount: 99.0,
            cycle: .monthly,
            nextBillingDate: ISO8601DateFormatter().date(from: "2026-07-18T00:00:00Z") ?? Date(),
            categoryId: "subscriptions",
            accountId: "bank",
            autoDeduct: false,
            isPaused: true,
            isTrial: false,
            status: "cancelled",
            sfSymbol: "camera.fill",
            colorHex: "#FF375F",
            isDarkBadge: true
        ),
        Subscription(
            id: UUID(uuidString: "E3A53877-E6E2-4EC9-9552-19130756DE59") ?? UUID(),
            name: "Whatsapp",
            amount: 79.0,
            cycle: .monthly,
            nextBillingDate: ISO8601DateFormatter().date(from: "2026-07-24T00:00:00Z") ?? Date(),
            categoryId: "subscriptions",
            accountId: "bank",
            autoDeduct: false,
            isPaused: true,
            isTrial: false,
            status: "cancelled",
            sfSymbol: "bubble.left.and.bubble.right.fill",
            colorHex: "#30D158",
            isDarkBadge: true
        ),
        Subscription(
            id: UUID(uuidString: "F97D3200-573E-4B32-BC1D-9A9A0F798C65") ?? UUID(),
            name: "Google Gemini Pro",
            amount: 399.0,
            cycle: .monthly,
            nextBillingDate: ISO8601DateFormatter().date(from: "2027-08-20T00:00:00Z") ?? Date(),
            categoryId: "subscriptions",
            accountId: "bank",
            autoDeduct: false,
            isPaused: false,
            isTrial: false,
            status: "active",
            sfSymbol: "sparkles",
            colorHex: "#007AFF",
            isDarkBadge: true
        ),
        Subscription(
            id: UUID(uuidString: "D29B4203-887E-41B0-BFB6-72C90EA8CEE9") ?? UUID(),
            name: "Google Gemini Pro Jio plan",
            amount: 35000.0,
            cycle: .monthly,
            nextBillingDate: ISO8601DateFormatter().date(from: "2028-02-23T00:00:00Z") ?? Date(),
            categoryId: "subscriptions",
            accountId: "bank",
            autoDeduct: false,
            isPaused: false,
            isTrial: true,
            status: "active",
            sfSymbol: "sparkles",
            colorHex: "#5856D6",
            isDarkBadge: true
        ),
    ]
    
    static var transactions: [Transaction] {
        let formatter = ISO8601DateFormatter()
        return [
            Transaction(
                id: UUID(uuidString: "C7374BFA-7828-4343-9731-FDC2F63C5066") ?? UUID(),
                title: "Subscription Payment: Apple Music",
                amount: 59.0,
                type: .expense,
                categoryId: "subscriptions",
                accountId: "bank",
                date: formatter.date(from: "2026-09-01T08:57:04Z") ?? Date(),
                subscriptionId: "E0C328A0-B6BD-4396-B32E-1E2ED7D6A7F5"
            ),
            Transaction(
                id: UUID(uuidString: "B27EE56D-F13D-4E75-8889-5A84CB102395") ?? UUID(),
                title: "unkno",
                amount: 60.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2026-08-01T16:22:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "4310E0EA-9C61-4B6E-85EC-1DC1985656EC") ?? UUID(),
                title: "extra",
                amount: 15.0,
                type: .expense,
                categoryId: "medicin_194cfec8-cd29-45f9-a9ab-00ee2a88b86c",
                accountId: "bank",
                date: formatter.date(from: "2026-08-31T16:16:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "A5ED355F-14B4-4583-9A4F-5C7CCA4EAAE8") ?? UUID(),
                title: "Metro",
                amount: 60.0,
                type: .expense,
                categoryId: "travel_d8736db9-398b-4339-a4b3-7aa3b5ee55e0",
                accountId: "cash",
                date: formatter.date(from: "2026-08-30T16:11:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "F5A65DBF-8B6A-4BDB-A5EF-2B52CE853BFD") ?? UUID(),
                title: "Pop Corn toxic",
                amount: 400.0,
                type: .expense,
                categoryId: "food",
                accountId: "cash",
                date: formatter.date(from: "2026-08-30T16:11:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "FE8FDD61-3BDC-414D-9595-416F72A30BC6") ?? UUID(),
                title: "pani puri",
                amount: 35.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-31T15:37:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "15A47B86-E73A-41AA-AE5C-4B2985015443") ?? UUID(),
                title: "Levosiz M",
                amount: 99.0,
                type: .expense,
                categoryId: "medicin_194cfec8-cd29-45f9-a9ab-00ee2a88b86c",
                accountId: "bank",
                date: formatter.date(from: "2026-08-31T15:37:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "D3A5B20C-4608-4159-8D7F-A278C88AA877") ?? UUID(),
                title: "Elvi 3rd month",
                amount: 40150.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-08-31T15:25:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "55CD692E-B36A-48AC-B6C1-74D20497167A") ?? UUID(),
                title: "Metro Parking",
                amount: 40.0,
                type: .expense,
                categoryId: "parking_7ea8830e-000a-4f72-92d4-7a29be989330",
                accountId: "cash",
                date: formatter.date(from: "2026-08-30T08:27:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "C74943D5-5E3A-45E1-A4D7-9275AD1A5945") ?? UUID(),
                title: "all season",
                amount: 40.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-26T04:16:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "DC0ABE07-2ACE-4AB9-84E9-9F32DA6FF524") ?? UUID(),
                title: "Boys meghana treat",
                amount: 3331.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-28T15:39:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "B5E1D7E2-0FE3-462C-A2BC-9420A319B204") ?? UUID(),
                title: "boys treat",
                amount: 3000.0,
                type: .income,
                categoryId: "appa_abf1da64-a521-42cf-93f8-f8856dbe92a9",
                accountId: "bank",
                date: formatter.date(from: "2026-08-28T15:39:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9C8A80AB-5CBB-417D-BD03-8CD72E830BB6") ?? UUID(),
                title: "Bday Asha Aunty",
                amount: 3000.0,
                type: .income,
                categoryId: "gift",
                accountId: "cash",
                date: formatter.date(from: "2026-08-27T17:00:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "D6849EF6-6A10-457C-B248-BB5060A383D8") ?? UUID(),
                title: "Ammama bday gift",
                amount: 2000.0,
                type: .income,
                categoryId: "gift",
                accountId: "cash",
                date: formatter.date(from: "2026-08-21T16:59:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "8A4A09E6-4134-437F-A0BF-DF716F8112F6") ?? UUID(),
                title: "Bday shirt 3116 - 2000",
                amount: 2000.0,
                type: .expense,
                categoryId: "essentials_1e661c95-fb48-4905-b1eb-4a761e2b3068",
                accountId: "cash",
                date: formatter.date(from: "2026-08-27T16:58:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "6E6B26EF-8414-43A6-A900-63323EAA5920") ?? UUID(),
                title: "Soda factory games",
                amount: 300.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2026-08-27T16:58:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "001CF711-0338-40CC-A4C6-CB1CEAEB19E4") ?? UUID(),
                title: "gobi",
                amount: 125.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-26T13:27:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "2A5DEE77-4373-4B7C-9A21-BB6AD36F4971") ?? UUID(),
                title: "Maid aunty son gift chocolate",
                amount: 192.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-26T06:59:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "1A0C0135-4E38-4234-8DC3-44FF9BF96E6E") ?? UUID(),
                title: "Cat",
                amount: 180.0,
                type: .expense,
                categoryId: "cat_d6049b7b-6a4b-4ed9-bfdd-297c067398e3",
                accountId: "bank",
                date: formatter.date(from: "2026-08-25T06:57:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "04B08BDD-44E7-45F7-878F-1C898EC17AE3") ?? UUID(),
                title: "Appa",
                amount: 1000.0,
                type: .income,
                categoryId: "appa_abf1da64-a521-42cf-93f8-f8856dbe92a9",
                accountId: "bank",
                date: formatter.date(from: "2026-08-25T06:57:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9D99800E-79A6-4273-A068-15408C4A7F4E") ?? UUID(),
                title: "gobi",
                amount: 40.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-24T18:08:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "4D53BA3C-E374-4B2E-97E0-2BBE45C67139") ?? UUID(),
                title: "all season",
                amount: 242.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-23T16:52:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "BF33C844-3A78-45AD-B1AC-1B67F8F18CEB") ?? UUID(),
                title: "Groceries",
                amount: 75.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-22T03:45:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "0CB6A290-AD49-4BF5-BE55-6FACDC330E65") ?? UUID(),
                title: "Lemon",
                amount: 20.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-22T03:44:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "FA3E8DA5-3680-4CDC-B734-36E4F6F66B30") ?? UUID(),
                title: "Gemini Pro refund",
                amount: 100.64,
                type: .income,
                categoryId: "refund",
                accountId: "bank",
                date: formatter.date(from: "2026-08-23T03:42:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "028941E7-1ED3-46BB-B160-138C70063385") ?? UUID(),
                title: "Gemini Plus autopay back",
                amount: 2.0,
                type: .income,
                categoryId: "refund",
                accountId: "bank",
                date: formatter.date(from: "2026-08-21T14:32:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "EF30D4CE-F1FB-4905-8054-164E7FE8535A") ?? UUID(),
                title: "Scooter Air",
                amount: 10.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2026-08-21T14:31:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "D8CCA34E-AC3C-4767-B2EE-019BD56C2BFC") ?? UUID(),
                title: "VEDANTA",
                amount: 16.0,
                type: .income,
                categoryId: "stock_income_d8cfb65d-bab7-4c48-afae-28bbbfa93d14",
                accountId: "bank",
                date: formatter.date(from: "2026-08-21T14:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "66FAE557-14BE-44EF-AF16-CEC5AA3A2C59") ?? UUID(),
                title: "All seasons",
                amount: 150.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-21T14:29:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "27B65F99-7363-4577-9840-77D9B0664065") ?? UUID(),
                title: "Gemini Pro AutoPay",
                amount: 2.0,
                type: .expense,
                categoryId: "subscriptions",
                accountId: "bank",
                date: formatter.date(from: "2026-08-20T13:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E9EF82A8-D81D-4193-8B6E-754DCE048B79") ?? UUID(),
                title: "Ajay angadi",
                amount: 30.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-20T13:28:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "2BA2BB80-6FDB-4956-9E8B-E8E19E310386") ?? UUID(),
                title: "Zepto",
                amount: 201.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-20T13:27:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "C36CD5D6-FA4A-4FFD-A629-F4A2B62E70FD") ?? UUID(),
                title: "Airtel Recharge 375",
                amount: 400.0,
                type: .expense,
                categoryId: "amazon_pay_balance_cfe5c8cf-78c0-4877-8c71-a76a4a872541",
                accountId: "bank",
                date: formatter.date(from: "2026-08-18T09:22:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "54CB351C-E1D4-4FBA-BED4-DF7C31191475") ?? UUID(),
                title: "SBI",
                amount: 236.0,
                type: .expense,
                categoryId: "anc_9bc1f674-5662-47b6-803f-a1b1d93878e0",
                accountId: "bank",
                date: formatter.date(from: "2026-08-18T09:21:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "1DFBA96B-8EAF-4A70-A530-A5D76774583F") ?? UUID(),
                title: "Sam and marshal Flipkart",
                amount: 803.0,
                type: .income,
                categoryId: "refund",
                accountId: "bank",
                date: formatter.date(from: "2026-08-17T12:55:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E01B94D6-5A62-4A5A-BD08-643CEEDDA3F4") ?? UUID(),
                title: "Sam n Marshal",
                amount: 812.0,
                type: .expense,
                categoryId: "essentials_1e661c95-fb48-4905-b1eb-4a761e2b3068",
                accountId: "bank",
                date: formatter.date(from: "2026-08-17T05:57:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "1290B1E6-A4D1-4E79-8CDA-6992713246BC") ?? UUID(),
                title: "Subscription Payment: Google One",
                amount: 130.0,
                type: .expense,
                categoryId: "subscriptions",
                accountId: "bank",
                date: formatter.date(from: "2026-08-16T05:45:00Z") ?? Date(),
                subscriptionId: "2E885DA4-B030-48D6-B983-BB32C502C979"
            ),
            Transaction(
                id: UUID(uuidString: "DB645153-50F3-46C8-81B0-E65D378B3368") ?? UUID(),
                title: "Amma chitranna",
                amount: 40.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-16T05:43:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "C0C19822-987F-4FB1-8F4D-19F6051A1A02") ?? UUID(),
                title: "zomato pizza",
                amount: 261.39,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-15T05:43:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "05FE9542-5D4A-4CCE-AB28-A917648A595C") ?? UUID(),
                title: "instamart",
                amount: 152.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-14T05:43:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "407AEFD2-3BE6-4C39-8B6C-3712185A3E59") ?? UUID(),
                title: "pani puri",
                amount: 35.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-13T15:31:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "6E1089DB-D228-4085-957D-C797FEC05083") ?? UUID(),
                title: "Gobi",
                amount: 40.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-13T15:31:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "C83198CC-4D78-4DC1-9561-85DAA76E15E2") ?? UUID(),
                title: "Amma Kitti",
                amount: 5000.0,
                type: .expense,
                categoryId: "lucky_chit_2c665d23-ad7a-495b-86f6-3305467e0d05",
                accountId: "bank",
                date: formatter.date(from: "2026-08-13T11:24:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "AFDA279D-4964-46AA-B8A5-074E33D4D0B9") ?? UUID(),
                title: "outside",
                amount: 40.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-13T05:46:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9152EFF2-2E04-4063-BA61-675D47D78B8D") ?? UUID(),
                title: "instamart",
                amount: 290.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-12T07:36:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "AFB22D2A-20B4-43DB-A0B3-798C51E77259") ?? UUID(),
                title: "student load",
                amount: 10000.0,
                type: .expense,
                categoryId: "appa_18058f26-bcc2-4437-9e03-6bd014966ca1",
                accountId: "bank",
                date: formatter.date(from: "2026-08-10T16:05:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "B9316055-7851-4846-B6C1-0CFFDBFA418C") ?? UUID(),
                title: "Flupkart Glasses",
                amount: 722.0,
                type: .income,
                categoryId: "refund",
                accountId: "bank",
                date: formatter.date(from: "2026-08-10T13:53:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "64C733BA-DC8C-4EF8-8405-CE89749A3191") ?? UUID(),
                title: "Whewt",
                amount: 20.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-10T13:51:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "BC4509DA-1490-4F1D-A19D-7C8879B28ACA") ?? UUID(),
                title: "briyani",
                amount: 170.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-09T16:10:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "D2B85FF5-3CC3-43D8-8D4D-724B0DBD3E34") ?? UUID(),
                title: "pani puri",
                amount: 35.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-09T13:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "128F5085-52CF-4858-B96D-D81844EF0A19") ?? UUID(),
                title: "instamart stationary plus icecream",
                amount: 157.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-09T13:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "75475D39-A0D6-4D10-9F2F-689E96AC20F1") ?? UUID(),
                title: "all season",
                amount: 31.0,
                type: .expense,
                categoryId: "stationary_9a2bcefa-171b-4bd8-92c7-307bf5528557",
                accountId: "bank",
                date: formatter.date(from: "2026-08-09T13:29:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "7928718A-C241-4724-A578-AF5FC27BE68F") ?? UUID(),
                title: "All Season chups",
                amount: 40.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-09T11:32:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "362713BA-EC19-40FC-AA68-1B1E8B36E9F0") ?? UUID(),
                title: "flipkart SnM glasses",
                amount: 812.0,
                type: .expense,
                categoryId: "essentials_1e661c95-fb48-4905-b1eb-4a761e2b3068",
                accountId: "bank",
                date: formatter.date(from: "2026-08-09T09:09:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "984512F5-5FCA-47F0-9E97-341F1D5D9379") ?? UUID(),
                title: "Boys plan b",
                amount: 800.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-08T01:54:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "A55F46CC-4EDE-4529-ABD7-06F77B56A1BA") ?? UUID(),
                title: "Puliyogre",
                amount: 50.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-07T15:47:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "A1125E7C-FD16-4536-A793-44A0ACBB6872") ?? UUID(),
                title: "Gundu Briyani",
                amount: 170.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-07T15:46:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "0BB9D464-F934-44DF-89D1-3577C38C8B30") ?? UUID(),
                title: "Cat",
                amount: 335.0,
                type: .expense,
                categoryId: "cat_d6049b7b-6a4b-4ed9-bfdd-297c067398e3",
                accountId: "bank",
                date: formatter.date(from: "2026-08-07T14:39:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "DE0641BB-6840-4D7D-A9D0-FBA329AB3291") ?? UUID(),
                title: "gobi",
                amount: 135.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-06T14:59:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E5B07813-66E9-4CF9-BDD9-B6AEB9302638") ?? UUID(),
                title: "Milk",
                amount: 54.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-06T11:33:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "02FE34F5-5A34-4772-8CF8-4B513431B430") ?? UUID(),
                title: "All Season",
                amount: 125.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-06T11:27:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "64FF3CB0-D296-4718-81EB-5E56088CAE4A") ?? UUID(),
                title: "HDFC",
                amount: 52.0,
                type: .income,
                categoryId: "stock_income_d8cfb65d-bab7-4c48-afae-28bbbfa93d14",
                accountId: "bank",
                date: formatter.date(from: "2026-08-05T11:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "4332804B-4BF2-414D-BA59-FD4A5BFDC7F5") ?? UUID(),
                title: "zepto",
                amount: 164.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-05T09:15:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "17682185-0B6A-4ED3-9BF8-9F5291D8DA36") ?? UUID(),
                title: "Gobi",
                amount: 430.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-04T16:54:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "5EDDE43B-F57A-4771-AD78-6E51320CEFBA") ?? UUID(),
                title: "Sandwich",
                amount: 95.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-04T16:54:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "3B23C58E-5608-4168-8D66-4F7F7A1E87A0") ?? UUID(),
                title: "Mahindra n Mahindra",
                amount: 66.0,
                type: .income,
                categoryId: "stock_income_d8cfb65d-bab7-4c48-afae-28bbbfa93d14",
                accountId: "bank",
                date: formatter.date(from: "2026-08-04T11:36:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "AC2A2EE0-FB45-4C1A-8EC1-AE397B38B97E") ?? UUID(),
                title: "curd",
                amount: 28.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-02T08:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "7B7A4C38-0D16-4AF7-8C1A-1551FB4221EE") ?? UUID(),
                title: "supriya akka payback",
                amount: 20000.0,
                type: .expense,
                categoryId: "appa_18058f26-bcc2-4437-9e03-6bd014966ca1",
                accountId: "bank",
                date: formatter.date(from: "2026-08-02T06:13:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "D4199B1D-3530-489E-A457-CBDBF198FB0B") ?? UUID(),
                title: "Shopright",
                amount: 75.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-08-02T06:13:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "4D8C66FA-90CF-400E-A76E-A889BCADE6E4") ?? UUID(),
                title: "Baskin Robbins",
                amount: 326.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-08-01T14:56:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9F020627-3B5D-4EBB-A0E8-758E44D379B4") ?? UUID(),
                title: "Flipkart SnM glasses",
                amount: 731.0,
                type: .expense,
                categoryId: "essentials_1e661c95-fb48-4905-b1eb-4a761e2b3068",
                accountId: "bank",
                date: formatter.date(from: "2026-08-01T11:10:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9E5018D1-7542-4592-84D1-8640AE5E704F") ?? UUID(),
                title: "Amma",
                amount: 150.0,
                type: .income,
                categoryId: "amma_fbe39d49-fe39-4ee5-8ccc-8c3cbe1af1d7",
                accountId: "bank",
                date: formatter.date(from: "2026-07-31T14:47:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "1270FD74-3431-4EA6-B87F-26A1FE646F8A") ?? UUID(),
                title: "maggie",
                amount: 103.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-31T14:47:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "4C8032B0-D96F-46F0-A8E4-7B1961429E6A") ?? UUID(),
                title: "BAJAJ FINANCE",
                amount: 6.0,
                type: .income,
                categoryId: "stock_income_d8cfb65d-bab7-4c48-afae-28bbbfa93d14",
                accountId: "bank",
                date: formatter.date(from: "2026-07-31T08:51:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "CE12A421-A04C-43C4-B242-7AA8CBB6D932") ?? UUID(),
                title: "2nd Salary",
                amount: 41400.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-07-31T00:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "5DE6D1F2-6195-4A91-B779-A655151E95C3") ?? UUID(),
                title: "chips",
                amount: 100.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-30T09:12:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "464CCF58-EAF9-44E9-9F96-F8B26AB81970") ?? UUID(),
                title: "Appa",
                amount: 100.0,
                type: .income,
                categoryId: "appa_abf1da64-a521-42cf-93f8-f8856dbe92a9",
                accountId: "bank",
                date: formatter.date(from: "2026-07-30T09:12:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "86F2A711-6D52-44A9-A9B8-46B5EEC4D15B") ?? UUID(),
                title: "Subscription Payment: Apple Music",
                amount: 59.0,
                type: .expense,
                categoryId: "subscriptions",
                accountId: "bank",
                date: formatter.date(from: "2026-07-30T00:36:00Z") ?? Date(),
                subscriptionId: "E0C328A0-B6BD-4396-B32E-1E2ED7D6A7F5"
            ),
            Transaction(
                id: UUID(uuidString: "B09AF986-1DEF-4A0D-A191-B37DA97FD968") ?? UUID(),
                title: "Tailor",
                amount: 50.0,
                type: .expense,
                categoryId: "essentials_1e661c95-fb48-4905-b1eb-4a761e2b3068",
                accountId: "bank",
                date: formatter.date(from: "2026-07-28T13:16:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "416DC594-23E8-4A18-B289-CBCC55EE9098") ?? UUID(),
                title: "All Season",
                amount: 175.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-26T15:33:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "DEAC254D-5A47-40A0-918A-2A8F012CCF35") ?? UUID(),
                title: "Zepto",
                amount: 184.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-26T13:34:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "B4A5F652-E707-4890-AB99-5104966F3512") ?? UUID(),
                title: "pani puri",
                amount: 35.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-26T09:12:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "0D9615C7-4299-4553-B94E-CB7C9FFE96B3") ?? UUID(),
                title: "iceream",
                amount: 240.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-25T09:37:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "6DC55CDF-F3D1-457E-9B36-E267EBBB158E") ?? UUID(),
                title: "kachori",
                amount: 40.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-25T09:23:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "77DE9048-90AD-4C8C-A90C-61513C28BB3A") ?? UUID(),
                title: "Food",
                amount: 180.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-25T09:11:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "55CB7053-8669-4CF6-AF5F-EFED31464936") ?? UUID(),
                title: "Blind Music performance",
                amount: 50.0,
                type: .expense,
                categoryId: "help_6c2c738b-a421-48c0-9195-4385e0358432",
                accountId: "bank",
                date: formatter.date(from: "2026-07-23T15:06:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "EBC3EA8B-9FF4-482C-B6A3-00467FAF0909") ?? UUID(),
                title: "pani puri",
                amount: 35.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-23T15:04:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "B8857171-99CA-4E7B-8A30-39863BB90CB8") ?? UUID(),
                title: "Bonda",
                amount: 40.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-23T15:04:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9236FFDB-AC25-4D0D-AEAB-9C2FF711B2D6") ?? UUID(),
                title: "milk",
                amount: 64.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-23T15:04:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "BAEF52DA-FADE-44DE-8196-52D8B2FBBC9F") ?? UUID(),
                title: "All seasons",
                amount: 73.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-22T15:07:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "564EB386-A8AD-48F3-80FE-D66F03D091AB") ?? UUID(),
                title: "gobi",
                amount: 135.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-22T14:55:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "A6367942-9787-4636-ADC9-C3B4A3ACC0BF") ?? UUID(),
                title: "gobi",
                amount: 45.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-22T14:55:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "36A1CCC5-AF41-41FE-B689-E704553AC93C") ?? UUID(),
                title: "Briyani",
                amount: 340.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-22T14:55:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "EA31993E-C721-42E2-BF0C-411D35DA57EE") ?? UUID(),
                title: "all season",
                amount: 40.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-21T09:40:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "085FB5EA-5555-475D-A0F4-FB78A3E2E4C0") ?? UUID(),
                title: "Cat",
                amount: 135.0,
                type: .expense,
                categoryId: "cat_d6049b7b-6a4b-4ed9-bfdd-297c067398e3",
                accountId: "bank",
                date: formatter.date(from: "2026-07-20T15:36:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "749EF63B-BB80-41F9-8D68-095FD111DC1C") ?? UUID(),
                title: "orion",
                amount: 60.0,
                type: .expense,
                categoryId: "parking_7ea8830e-000a-4f72-92d4-7a29be989330",
                accountId: "bank",
                date: formatter.date(from: "2026-07-20T15:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E5A28880-E1CA-421D-8FEE-B97284EA2F68") ?? UUID(),
                title: "instamart",
                amount: 157.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-20T08:28:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "BF13CBE4-81A8-449F-8C09-6C770E50D133") ?? UUID(),
                title: "all seasons",
                amount: 47.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-18T16:38:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "B590572A-BB7B-47A2-A56F-9875DE1457E9") ?? UUID(),
                title: "Amazon Min",
                amount: 168.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-18T08:25:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E8FB0732-7607-45E7-96C4-E286671CEA7E") ?? UUID(),
                title: "coffee",
                amount: 20.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-17T08:25:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "B361492B-60AD-4DC5-8213-539DE5239C01") ?? UUID(),
                title: "flipkart min",
                amount: 164.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-16T15:33:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "66BD7E14-CEF4-486B-BF46-6E57E53272B7") ?? UUID(),
                title: "chats",
                amount: 80.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-16T15:33:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "51FC60F2-79F0-4BDE-9D7D-A5CED94C410E") ?? UUID(),
                title: "Cat",
                amount: 90.0,
                type: .expense,
                categoryId: "cat_d6049b7b-6a4b-4ed9-bfdd-297c067398e3",
                accountId: "bank",
                date: formatter.date(from: "2026-07-15T15:14:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "20024A52-CBCF-4319-9DBC-9C7A9703C2CF") ?? UUID(),
                title: "all seasons",
                amount: 62.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-14T15:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "8A9D1057-AD6E-4072-A755-01F5AC3A0249") ?? UUID(),
                title: "pani puri",
                amount: 70.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-13T09:12:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "6E772290-3EEA-48D5-BA35-D273B5FA80BA") ?? UUID(),
                title: "zepto",
                amount: 141.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-12T08:05:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "40905EB0-C649-4D8F-80FA-66A9FA0E679E") ?? UUID(),
                title: "tomato",
                amount: 22.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-12T02:01:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "8F750948-91EC-4F0C-9997-C7E09DA1AD4D") ?? UUID(),
                title: "All season",
                amount: 74.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-12T01:52:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "5E824978-C225-4592-82E8-81A6CAA273DC") ?? UUID(),
                title: "college sweet",
                amount: 630.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-11T06:10:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E667DA86-A3A4-436B-B4C2-7CE9A7C6B9A9") ?? UUID(),
                title: "Amma",
                amount: 500.0,
                type: .expense,
                categoryId: "amma_d88ec4dd-0186-4c31-860b-4314d1edd7d1",
                accountId: "bank",
                date: formatter.date(from: "2026-07-11T05:58:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "8C3753FE-F0CA-4E7C-87FE-670D97FAEE3E") ?? UUID(),
                title: "Student Loan",
                amount: 10000.0,
                type: .expense,
                categoryId: "appa_18058f26-bcc2-4437-9e03-6bd014966ca1",
                accountId: "bank",
                date: formatter.date(from: "2026-07-10T17:48:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "3991FF63-C57A-424C-91D8-C98420D4D294") ?? UUID(),
                title: "zepto",
                amount: 154.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-10T15:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "18AC7611-E400-4B09-84D4-FD411DAB1F5B") ?? UUID(),
                title: "nandhini",
                amount: 25.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-10T15:09:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "A137F2BC-6D5E-458B-99E0-9D8C3B01599B") ?? UUID(),
                title: "All season",
                amount: 75.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-09T09:17:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "1B4ABF46-3D53-427B-BF51-434A044311C5") ?? UUID(),
                title: "Groceries",
                amount: 10.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-09T09:14:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "5C869E32-987F-438E-B739-27C474E1B02D") ?? UUID(),
                title: "spin",
                amount: 250.0,
                type: .expense,
                categoryId: "haircut_0c840b17-b63d-4246-bdba-8bf571b521a8",
                accountId: "bank",
                date: formatter.date(from: "2026-07-08T13:53:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "5F72FDBB-E5A4-420D-9E79-543BA416576B") ?? UUID(),
                title: "hot chips",
                amount: 100.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-08T10:04:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "1B27679E-BB63-446F-8AEA-917B6B879F50") ?? UUID(),
                title: "Amazon Pay Balance",
                amount: 140.0,
                type: .expense,
                categoryId: "amazon_pay_balance_cfe5c8cf-78c0-4877-8c71-a76a4a872541",
                accountId: "bank",
                date: formatter.date(from: "2026-07-07T08:22:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "DD706F2A-7CB3-4078-B99B-8D449552984E") ?? UUID(),
                title: "Bike Loan",
                amount: 25000.0,
                type: .expense,
                categoryId: "appa_18058f26-bcc2-4437-9e03-6bd014966ca1",
                accountId: "bank",
                date: formatter.date(from: "2026-07-05T15:52:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "96870799-B4FE-4E00-A02C-39EF05CC4932") ?? UUID(),
                title: "Nandini Badam milk",
                amount: 25.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-05T15:31:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "858C5698-D735-4CB1-8206-3A6A782FE0C2") ?? UUID(),
                title: "whiskas",
                amount: 180.0,
                type: .expense,
                categoryId: "cat_d6049b7b-6a4b-4ed9-bfdd-297c067398e3",
                accountId: "bank",
                date: formatter.date(from: "2026-07-05T15:24:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "46925A62-30E5-4F58-9768-75DB4030ECA7") ?? UUID(),
                title: "Gundu Palav World Briyani Day",
                amount: 240.0,
                type: .expense,
                categoryId: "food",
                accountId: "bank",
                date: formatter.date(from: "2026-07-05T15:13:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "EB622411-18DC-4A8F-820E-27DEBACA7A89") ?? UUID(),
                title: "Flipkart Min",
                amount: 140.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "cash",
                date: formatter.date(from: "2026-07-05T08:38:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "64E2BF0B-F49F-4AAD-9EDA-E25B26DFE4C9") ?? UUID(),
                title: "Chetana Aunty Amma",
                amount: 1050.0,
                type: .expense,
                categoryId: "amma_d88ec4dd-0186-4c31-860b-4314d1edd7d1",
                accountId: "bank",
                date: formatter.date(from: "2026-07-04T04:51:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "2CE51A43-6BA5-4656-8633-8C4084AB15C3") ?? UUID(),
                title: "Groceries",
                amount: 80.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-04T04:51:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "81C18199-5D53-4D6C-8DB6-D107F8533F88") ?? UUID(),
                title: "Amazon",
                amount: 500.0,
                type: .expense,
                categoryId: "amma_d88ec4dd-0186-4c31-860b-4314d1edd7d1",
                accountId: "bank",
                date: formatter.date(from: "2026-07-04T04:50:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "7D327D82-55B5-42C0-86FB-C2887ADBD2C2") ?? UUID(),
                title: "Blinkit",
                amount: 164.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-03T04:50:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "809834CE-79F1-4C42-900A-2DBC32418D72") ?? UUID(),
                title: "Activa",
                amount: 100.0,
                type: .expense,
                categoryId: "transport",
                accountId: "bank",
                date: formatter.date(from: "2026-07-03T04:49:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "C3D29340-9EC7-4E57-B75A-1DEE98E1200A") ?? UUID(),
                title: "KitKat Thatan Angdi",
                amount: 20.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-02T04:49:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "224A61E1-C961-4052-BA99-04F6EB64BD8A") ?? UUID(),
                title: "Subscription Payment: Apple Music",
                amount: 59.0,
                type: .expense,
                categoryId: "subscriptions",
                accountId: "bank",
                date: formatter.date(from: "2026-07-01T04:55:00Z") ?? Date(),
                subscriptionId: "E0C328A0-B6BD-4396-B32E-1E2ED7D6A7F5"
            ),
            Transaction(
                id: UUID(uuidString: "D32D9F6A-D863-4B3C-9ED3-453BAA46CD38") ?? UUID(),
                title: "Match Box Thatan Angdi",
                amount: 20.0,
                type: .expense,
                categoryId: "groceries",
                accountId: "bank",
                date: formatter.date(from: "2026-07-01T04:48:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "6CA43721-AE14-45D7-B531-F83FC051B4F5") ?? UUID(),
                title: "First Salary Elvi",
                amount: 41400.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-06-30T04:47:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "78AEC946-166A-49D6-8623-F8BA37B52E93") ?? UUID(),
                title: "Appa",
                amount: 1003.0,
                type: .income,
                categoryId: "appa_abf1da64-a521-42cf-93f8-f8856dbe92a9",
                accountId: "bank",
                date: formatter.date(from: "2026-06-29T04:46:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "C7E72CEB-6098-4365-8E34-62FBE9AE22DE") ?? UUID(),
                title: "burn",
                amount: 20000.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2026-05-31T09:36:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "705D752E-282F-405B-86DB-320BE64E324D") ?? UUID(),
                title: "4th stipend",
                amount: 10000.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-05-31T09:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "9C3AC64F-D3BD-4AAF-86D8-366F0EF89A8C") ?? UUID(),
                title: "3rd stipend",
                amount: 10000.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-04-30T09:35:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "4F79AB6A-798F-4812-83CE-8C8F69AB3C89") ?? UUID(),
                title: "2nd stipend burn",
                amount: 10000.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2026-04-01T09:33:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "8045083D-A6DC-4DF1-907D-B83EF4CCAE1C") ?? UUID(),
                title: "first stipend burn",
                amount: 10000.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2026-04-01T09:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "6648744E-8542-4222-9C13-33DED71B3856") ?? UUID(),
                title: "2nd stipend",
                amount: 10000.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-03-30T09:32:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "E36EC3AC-DB54-4D15-8F12-4520CAF3729C") ?? UUID(),
                title: "first stipend elvi",
                amount: 10000.0,
                type: .income,
                categoryId: "paycheck",
                accountId: "bank",
                date: formatter.date(from: "2026-02-28T09:30:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "A3315430-6529-4E7E-A269-D6799A32FA21") ?? UUID(),
                title: "Empty",
                amount: 27710.0,
                type: .expense,
                categoryId: "extra_ac33f52e-2778-42ab-ba60-83151a701440",
                accountId: "bank",
                date: formatter.date(from: "2025-10-17T09:25:00Z") ?? Date(),
                subscriptionId: nil
            ),
            Transaction(
                id: UUID(uuidString: "5059E31A-CFA5-47AC-8B9D-E27113EF434F") ?? UUID(),
                title: "Invincible freelance first pay check",
                amount: 27710.0,
                type: .income,
                categoryId: "freelance",
                accountId: "bank",
                date: formatter.date(from: "2025-10-17T09:23:00Z") ?? Date(),
                subscriptionId: nil
            ),
        ]
    }
}
