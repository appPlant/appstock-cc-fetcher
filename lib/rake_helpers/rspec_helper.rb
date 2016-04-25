
# Methods to be used in Rakefile related to RSpec.
module RSpecHelper
  # Set the spec task as default rake task.
  def set_spec_as_default_task
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(:spec) do |t|
      t.rspec_opts = '--format documentation --color --require spec_helper'
    end

    task default: :spec
  rescue LoadError # rubocop:disable Lint/HandleExceptions
  end
end
