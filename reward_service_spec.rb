require_relative 'rewards_service'
require 'byebug'

RSpec.describe RewardsService do
  let(:customer_purchases) do
    [
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
  end

  let(:reward_rules) do
    {
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
  end

  let(:service) { RewardsService.new(customer_purchases, reward_rules) }

  describe '#rewards' do
    context 'when a customer qualifies for multiple rewards' do
      it 'applies the latest matching rule' do
        # For customer_id 65:
        # - 1st purchase qualifies for the "purchase greater than x" rule
        # - 2nd purchase qualifies for the "purchase on nth date" rule (May 4th)
        # - 3rd purchase qualifies for the "purchase greater than x" rule again
  
        rewards = service.rewards([65])
        
        # Expecting that the latest rule is applied, so "purchase on nth date" should apply
        expect {
          service.rewards([65])
        }.to output(/Rewards won for customer 65:/).to_stdout
        
        expect {
          service.rewards([65])
        }.to output(/  Rule: {:date_of_purchase=>4,/).to_stdout  # "purchase on nth date" rule should apply here
  
        expect {
          service.rewards([65])
        }.to output(/  Purchases:.*1600/).to_stdout  # The second purchase made on May 4th qualifies for this rule
      end
    end

    context 'when multiple purchases for a customer qualify under the same rule' do
      let(:customer_purchases) do
        [
            { customer_id: 999, purchase_amount_cents: 1000, created_at: Time.utc(2025, 3, 1, 10, 0) }, # Earlier purchase
            { customer_id: 999, purchase_amount_cents: 1200, created_at: Time.utc(2025, 3, 2, 10, 0) }, # Another purchase
            { customer_id: 999, purchase_amount_cents: 1500, created_at: Time.utc(2025, 3, 4, 10, 0) }, # This purchase on March 4 should match `date_of_purchase: 4` rule
            { customer_id: 999, purchase_amount_cents: 1800, created_at: Time.utc(2025, 3, 6, 10, 0) }  # Recent purchase
        ]
        
      end
      it 'applies the latest rule with created_at' do
        # For customer_id 999:
        # - 3 purchases made recently, the latest one should win
        
        serviced = service.rewards([999])
        expect {
          service.rewards([999])
        }.to output(/Rewards won for customer 999:/).to_stdout
  
        # The matching rule should be "purchase on nth date" (March 4th)
        expect {
          service.rewards([999])
        }.to output(/  Rule: {:date_of_purchase=>4,/).to_stdout
  
        # The matching purchase should be the one made on March 4th (1200 cents)
        expect {
          service.rewards([999])
        }.to output(/  Purchases:.*1500/).to_stdout
      end
    end

    context 'when a customer qualifies for no reward' do
      it 'outputs no reward message' do
        service.rewards([4465])
        expect {
          service.rewards([4465])
        }.to output(/No rewards for customer 4465./).to_stdout
      end
    end

    context 'when a customer qualifies for a reward based on purchase amount' do
      it 'applies the purchase amount greater than x rule' do
        service.rewards([12445])

        expect {
          service.rewards([12445])
        }.to output(/Rewards won for customer 12445:/).to_stdout
        expect {
          service.rewards([12445])
        }.to output(/  Rule: {:purchase_amount=>1500,/).to_stdout
        expect {
          service.rewards([12445])
        }.to output(/  Purchases:.*1800/).to_stdout
      end
    end

    context 'when the latest rule is added to the system' do
      it 'applies the newest rule with created_at timestamp' do
        new_rule = { purchase_amount: 1500, reward_text: "New rule, next purchase free :-)", created_at: Time.now.utc + 1 * 86400 }
        service.instance_variable_get(:@rewards)[:purchase_greater_than_x] << new_rule

        service.rewards([65])

        expect {
          service.rewards([65])
        }.to output(/Rewards won for customer 65:/).to_stdout
        expect {
          service.rewards([65])
        }.to output(/  Rule: {:purchase_amount=>1500,/).to_stdout
        expect {
          service.rewards([65])
        }.to output(/  Purchases:.*1600/).to_stdout
      end
    end
  end
end
