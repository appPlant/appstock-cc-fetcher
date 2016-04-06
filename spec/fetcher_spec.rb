require 'fakefs/spec_helpers'

RSpec.describe Fetcher do
  let(:fetcher) { described_class.new }
  subject { fetcher }

  it { is_expected.to respond_to(:branches, :stocks, :linked_pages, :run) }

  # TODO: more specs
end
