class RewardsService
  REWARD_RULES = {
    purchase_greater_than_x: [
      { purchase_amount: 1500, reward_text: "Your next purchase is free :-)", created_at: Time.utc(2025, 3, 10, 10, 0) }
    ],
    nth_purchase_last_n_days: [
      { nth_purchase: 2, last_n_days: 30, reward_text: "You have 20% off for your next order :-)", created_at: Time.utc(2025, 3, 10, 12, 0) }
    ],
    purchase_on_nth_date: [
      { date_of_purchase: 4, reward_text: "Star Wars themed item added to your cart :-)", created_at: Time.utc(2025, 3, 10, 14, 0) }
    ]
  }

  CUSTOMER_PURCHASES = [
    { customer_id: 65, purchase_amount_cents: 1800, created_at: Time.utc(2009, 1, 2, 6, 1) },
    { customer_id: 31337, purchase_amount_cents: 6522, created_at: Time.utc(2009, 5, 4, 6, 12) },
    { customer_id: 4465, purchase_amount_cents: 987, created_at: Time.utc(2010, 8, 17, 11, 9) },
    { customer_id: 234234, purchase_amount_cents: 200, created_at: Time.utc(2010, 11, 1, 16, 12) },
    { customer_id: 12445, purchase_amount_cents: 1664, created_at: Time.utc(2010, 11, 18, 13, 19) },
    { customer_id: 234234, purchase_amount_cents: 1200, created_at: Time.utc(2010, 12, 2, 16, 12) },
    { customer_id: 12445, purchase_amount_cents: 1800, created_at: Time.utc(2010, 12, 3, 11, 17) },
    { customer_id: 65, purchase_amount_cents: 900, created_at: Time.utc(2011, 4, 28, 13, 16) },
    { customer_id: 65, purchase_amount_cents: 1600, created_at: Time.utc(2011, 5, 4, 11, 1) },
    { customer_id: 999, purchase_amount_cents: 1000, created_at: Time.now.utc - 10 * 86400 },
    { customer_id: 999, purchase_amount_cents: 1200, created_at: Time.now.utc - 6 * 86400 },
    { customer_id: 999, purchase_amount_cents: 1500, created_at: Time.now.utc - 2 * 86400 }
  ]

  def initialize(purchases = CUSTOMER_PURCHASES, rewards = REWARD_RULES)
    @purchases = purchases
    @rewards = rewards
  end

  def get_customer_ids
    @purchases.map { |p| p[:customer_id] }.uniq
  end

  def rewards(customer_ids = get_customer_ids)
    puts "Processing rewards for Customers: #{customer_ids.join(', ')}"
    customer_ids.each do |customer_id|
      customer_purchases = @purchases.select { |p| p[:customer_id] == customer_id }
      winning_rewards = evaluate_rewards(customer_purchases)

      if winning_rewards.any?
        puts "Rewards won for customer #{customer_id}:"
        winning_rewards.each do |reward|
          puts "  Rule: #{reward[:matching_rule]}"
          puts "  Purchases: #{reward[:reward_purchases]}"
        end
      else
        puts "No rewards for customer #{customer_id}."
      end
    end
  end

  private

  def evaluate_rewards(purchases)
    latest_rules = @rewards.transform_values do |rules|
      rules.max_by { |rule| rule[:created_at] }
    end

    rewards_by_rule = latest_rules.flat_map do |rule_type, rule|
      reward_purchases = send(rule_type, purchases, rule)
      next unless reward_purchases.any?

      reward_purchases.map do |purchase|
        { matching_rule: rule, reward_purchases: [purchase] }
      end
    end.compact

    if rewards_by_rule.any?
      latest_reward_rule = rewards_by_rule.max_by { |reward| reward[:matching_rule][:created_at] }
      rewards_by_rule.select { |reward| reward[:matching_rule] == latest_reward_rule[:matching_rule] }
    else
      []
    end
  end

  def purchase_greater_than_x(purchases, rule)
    purchases.select { |p| p[:purchase_amount_cents] > rule[:purchase_amount] }
  end

  def purchase_on_nth_date(purchases, rule)
    purchases.select { |p| p[:created_at].day == rule[:date_of_purchase] }
  end

  def nth_purchase_last_n_days(purchases, rule)
    recent_purchases = purchases.select { |p| (Time.now.utc - p[:created_at]) / 86400 <= rule[:last_n_days] }
    return [] if recent_purchases.size < rule[:nth_purchase]
  
    [recent_purchases[rule[:nth_purchase] - 1]]
  end
end