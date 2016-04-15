require 'fakefs/spec_helpers'

RSpec.describe Fetcher do
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
      before { fetcher.run }

      it("should't create the drop box") do
        expect(File).to_not exist(fetcher.drop_box)
      end
    end

    describe '#fetch(automotive supplier)' do
      include FakeFS::SpecHelpers

      before do
        stub_request(:get, /branch=2/i).to_timeout
        fetcher.run([2])
      end

      it('should create no files') do
        expect(Dir.entries(fetcher.drop_box).count).to be(2)
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

  describe '#run' do
    context 'when #branches returns car rental only' do
      include_examples '#run test suite', 'car_rentals.xml', 2, 1
    end

    context 'when #branches returns banking only' do
      include_examples '#run test suite', 'banking.xml', 4, 25
    end
  end
end
