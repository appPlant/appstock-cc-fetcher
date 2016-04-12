require 'fakefs/spec_helpers'

RSpec.describe Fetcher do
  let(:cc) { 'https://www.consorsbank.de/euroWebDe/servlets/financeinfos_ajax' }
  let(:base_url) { "#{cc}?version=2&#{params}" }
  let(:fetcher) { described_class.new }
  subject { fetcher }

  it { is_expected.to respond_to(:branches, :stocks, :linked_pages, :run) }

  describe '#follow_linked_pages?' do
    let(:params) { 'page=StocksFinder&FIGURE0=PER.EVALUATION&YEAR0=2016' }
    subject { fetcher.follow_linked_pages? url }

    context 'when its the head of the list' do
      let(:url) { "#{base_url}&branch=100" }
      it { is_expected.to be_truthy }
    end

    context 'when its the tail of the list' do
      let(:url) { "#{base_url}&branch=100&pageoffset=2" }
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
      before { fetcher.run }

      it("should't create the file box") do
        expect(File).to_not exist(fetcher.file_box)
      end
    end

    describe '#fetch(automotive supplier)' do
      include FakeFS::SpecHelpers

      before do
        stub_request(:get, /branch=2/i).to_timeout
        fetcher.run([2])
      end

      it('should create no files') do
        expect(Dir.entries(fetcher.file_box).count).to be(2)
      end
    end
  end

  context 'when the response has wrong content' do
    let(:params) { 'page=OptionsBranch' }
    let(:page) { Nokogiri::HTML('<xml></xml>') }

    describe '#branches' do
      before { stub_request(:get, base_url) }
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
  end

  context 'when the response has expected content' do
    let(:params) { 'page=OptionsBranch' }
    let(:page) { Nokogiri::HTML(content) }

    describe '#branches' do
      let(:content) { File.read('spec/fixtures/branches.xml') }
      subject { fetcher.branches.count }
      before { stub_request(:get, base_url).to_return(body: content) }
      it { is_expected.to be(76) }
    end

    context 'car rental sector' do
      let(:content) { File.read('spec/fixtures/car_rentals.xml') }

      describe '#stocks' do
        subject { fetcher.stocks(page).count }
        it { is_expected.to be(5) }
      end

      describe '#linked_pages' do
        subject { fetcher.linked_pages(page) }
        it { is_expected.to be_empty }
      end
    end

    context 'banking sector' do
      let(:content) { File.read('spec/fixtures/banking.xml') }

      describe '#stocks' do
        subject { fetcher.stocks(page).count }
        it { is_expected.to be(20) }
      end

      describe '#linked_pages' do
        subject { fetcher.linked_pages(page).count }
        it { is_expected.to be(24) }
      end
    end
  end

  # TODO: more specs
end
