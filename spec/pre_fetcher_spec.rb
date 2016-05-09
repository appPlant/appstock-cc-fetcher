RSpec.describe PreFetcher do
  let(:cc) { 'https://www.consorsbank.de/euroWebDe/servlets/financeinfos_ajax' }
  let(:base_url) { "#{cc}?version=2&#{params if defined? params}" }
  let(:fetcher) { described_class.new }
  let(:interfaces) { [:branches, :stocks, :linked_pages, :branch_url, :run] }
  subject { fetcher }

  it { is_expected.to respond_to(*interfaces) }

  describe '#branch_url' do
    context 'when called with UTF-8 chars' do
      it { expect { fetcher.branch_url('∫') }.to_not raise_error }
    end

    context 'when called for the 1st page of branch 1' do
      subject { fetcher.branch_url(1, page: 1).to_s }
      it { is_expected.to match('branch=1') }
      it { is_expected.to_not match('pageoffset') }
    end

    context 'when called for the 2nd page of branch 1' do
      subject { fetcher.branch_url(1, page: 2).to_s }
      it { is_expected.to match('branch=1') }
      it { is_expected.to match('pageoffset=2') }
    end
  end

  describe '#follow_linked_pages?' do
    subject { fetcher.follow_linked_pages? url }

    context 'when its the head of the list' do
      let(:url) { fetcher.branch_url(100).to_s }
      it { is_expected.to be_truthy }
    end

    context 'when its the tail of the list' do
      let(:url) { fetcher.branch_url(1, page: 2).to_s }
      it { is_expected.to be_falsy }
    end
  end

  context 'when the network is offline' do
    let(:params) { 'page=OptionsBranch' }
    before { stub_request(:get, base_url).to_timeout }

    describe '#branches' do
      subject { fetcher.branches }
      it { is_expected.to be_empty }
    end

    describe '#fetch' do
      subject { fetcher.run }
      it { is_expected.to be_empty }
    end
  end

  context 'when the response has wrong content' do
    let(:params) { 'page=OptionsBranch' }
    let(:page) { Nokogiri::HTML('') }

    before { stub_request(:get, base_url) }

    describe '#branches' do
      subject { fetcher.branches }
      it { is_expected.to be_empty }
    end

    describe '#stocks' do
      subject { fetcher.stocks(page) }
      it { is_expected.to be_empty }
    end

    describe '#linked_pages' do
      subject { fetcher.linked_pages(page) }
      it { is_expected.to be_empty }
    end

    describe '#fetch' do
      subject { fetcher.run }
      it { is_expected.to be_empty }
    end
  end

  context 'when the response has expected content' do
    let(:params) { 'page=OptionsBranch' }
    let(:page) { Nokogiri::HTML(content) }

    describe '#branches' do
      let(:content) { File.read('spec/fixtures/branches.xml') }
      subject { fetcher.branches.count }
      before { stub_request(:get, base_url).to_return(body: content) }
      it { is_expected.to eq(76) }
    end

    context 'car rental sector' do
      let(:content) { File.read('spec/fixtures/car_rentals.xml') }

      describe '#stocks' do
        subject { fetcher.stocks(page).count }
        it { is_expected.to eq(5) }
      end

      describe '#linked_pages' do
        subject { fetcher.linked_pages(page) }
        it { is_expected.to be_empty }
      end

      describe '#run' do
        before do
          allow(fetcher).to receive(:branches).and_return([1])
          @url    = stub_request(:get, /branch=1/i).to_return(body: content)
          @stocks = fetcher.run.count
        end

        it { expect(@url).to have_been_requested }
        it('should return 5') { expect(@stocks).to eq(5) }
      end
    end

    context 'banking sector' do
      let(:content) { File.read('spec/fixtures/banking.xml') }

      describe '#stocks' do
        subject { fetcher.stocks(page).count }
        it { is_expected.to eq(20) }
      end

      describe '#linked_pages' do
        subject { fetcher.linked_pages(page).count }
        it { is_expected.to eq(24) }
      end
    end
  end
end
