require 'spec_helper'

describe Invoice do
  it { is_expected.to belong_to(:customer) }
  it { is_expected.to belong_to(:company) }

  it { is_expected.to validate_presence_of(:customer) }
  it { is_expected.to validate_presence_of(:company) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:state) }

  context "when new" do
    specify { is_expected.not_to be_valid }

    its(:to_s) { should == "" }
  end

  context "when amount is nil" do
    its(:to_s) { should == "" }
  end

  context "when properly initialized" do
    subject { FactoryGirl.build :invoice }

    its(:to_s) { should == '' }
  end

  context "Attachments" do
    it { is_expected.to have_many(:attachments) }
  end

  context "Bookings" do
    it { is_expected.to have_many(:bookings) }
  end

  context "line_items" do
    it { is_expected.to have_many(:line_items) }

    subject { FactoryGirl.build(:invoice) }

    it "should be empty for new instance" do
      expect(subject.line_items).to be_empty
    end

    it "should create one booking per line_item" do
      subject.line_items << FactoryGirl.build(:banana)
      subject.line_items << FactoryGirl.build(:vat)
      subject.save

      expect(subject.bookings.size).to eq(2)
    end

    it "should build booking with value_date of invoice" do
      subject.line_items << FactoryGirl.build(:banana)
      subject.line_items << FactoryGirl.build(:contracting, :date => '2000-01-01')
      subject.save

      subject.bookings.each do |booking|
        expect(booking.value_date).to eq(subject.value_date)
      end
    end
  end

  describe 'webhook handling' do
    context 'state changes to paid' do
      let(:instance) { FactoryGirl.create(:invoice, state: :booked) }

      it 'calls WebhookNotifier' do
        expect(WebhookNotifier).to receive(:call).with(instance, :paid)
        instance.update_attributes state: :paid
      end
    end

    context 'state does not change to paid' do
      let(:instance) { FactoryGirl.create(:invoice, state: :paid) }

      it 'does not call WebhookNotifier' do
        expect(WebhookNotifier).to_not receive(:call)
        instance.update_attributes title: 'Something new'
      end
    end
  end
end
