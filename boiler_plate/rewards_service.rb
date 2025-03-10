class RewardsService
  REWARD_RULES = {
    "purchase_greater_than_x": [{purchase_amount: 1500, reward_text: "Your next purchase is free :-)", created_at: Time.now.utc} ],
    "nth_purchase_last_n_days": [{nth_purchase: 2, last_n_days: 30, reward_text: "You have 20% off for your next oder :-)", created_at: Time.now.utc}],
    "purchase_on_nth_date": [{date_of_purchase: 4, reward_text: "Star Wars themed item added to your cart :-)", created_at: Time.now.utc}]
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
    { customer_id: 65, purchase_amount_cents: 1600, created_at: Time.utc(2011, 5, 4, 11, 1) }
]
  
  def initialize(purchases, rewards)
    @purchases = purchases
    @rewards = rewards
  end

  def get_customer_ids
    CUSTOMER_PURCHASES.map { |p| p[:customer_id] }.uniq
  end

  def rewards(customer_ids = get_customer_ids)
    puts "Processing rewards for Customers #{customer_ids}"
    customer_ids.each do |customer_id|
      winning_rewards = []
      customer_purchases = @purchases.select{|p| p[:customer_id] == customer_id }
      REWARD_RULES.each do |rule_type, rules|
        rule = rules.sort_by { |rule| rule[:created_at] }.reverse.first
        case rule_type
        when :purchase_greater_than_x
          reward_purchases = purchase_greater_than_x(customer_purchases, rule)
          winning_rewards << {matching_rule: rule, reward_purchases: reward_purchases} if reward_purchases.length > 0
        else :nth_purchase_last_n_days
          reward_purchases = nth_purchase_last_n_days(customer_purchases, rule)
          winning_rewards << {matching_rule: rule, reward_purchases: reward_purchases} if reward_purchases.length > 0
        else :purchase_on_nth_date
          reward_purchases = purchase_on_nth_date(customer_purchases, rule)
          winning_rewards << {matching_rule: rule, reward_purchases: reward_purchases} if reward_purchases.length > 0
        end
        latest_reward = winning_rewards.max_by { |reward| reward[:matching_rule][:created_at] }
        puts "Reward won for customer #{customer_id} on the basis of #{latest_reward[:matching_rule]} for the purchases #{latest_reward[:reward_purchases]}"
      end
    end
  end

  def purchase_greater_than_x(purchases, rule)
    purchases.select{|p| p[:purchase_amount_cents] > rule[:reward_amount] }
  end

  def nth_purchase_last_n_days(purchases, rule)
    purchases.select { |p| ((Time.now.utc - p[:created_at])/86400).round <= rule[last_n_days] }
  end
  
  def nth_purchase_last_n_days(purchases, rule)
    recent_purchases = purchases.select { |p| (Time.now.utc - p[:created_at]) / 86400 <= rule[:last_n_days] }
    return [] if recent_purchases.size < rule[:nth_purchase]
  
    [recent_purchases[rule[:nth_purchase] - 1]]
  end
end
