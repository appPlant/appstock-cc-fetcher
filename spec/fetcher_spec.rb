RSpec.describe Fetcher do
  let(:fetcher) { described_class.new }
  subject { fetcher }

  it { is_expected.to respond_to(:run) }

  describe '#run' do
    let(:isins) { ['US30303M1027'] }
    let(:run) { -> { fetcher.run isins } }

    before do
      allow_any_instance_of(PreFetcher).to receive(:run).and_return(isins)
    end

    context 'when the network is offline' do
      before { stub_request(:get, %r{/rest/de/marketdata/stocks}).to_timeout }
      it { expect { run.call }.to_not raise_error }
    end

    context 'when stock is available' do
      let(:content) { IO.read('spec/fixtures/stock.available.json') }
      before { stub_request(:get, /id=US30303M1027/).to_return(body: content) }
      it { expect { run.call }.to_not raise_error }
      it('should return empty list') { expect(run.call).to_not be_empty }
    end

    context 'when stock is not available' do
      let(:content) { IO.read('spec/fixtures/stock.unavailable.json') }
      before { stub_request(:get, /id=US30303M1027/).to_return(body: content) }
      it { expect { run.call }.to_not raise_error }
      it('should return empty list') { expect(run.call).to be_empty }
    end
  end
end
