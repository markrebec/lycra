require 'spec_helper'

RSpec.describe Lycra do
  describe '.logger' do
    context 'when configured with a custom logger' do
      let(:logger) do
        Dir.mktmpdir do |dir|
          Logger.new(File.open(File.join(dir, 'lycra.log'), 'w'))
        end
      end

      before do
        Lycra.configuration.configure(logger: logger)
        Lycra.configuration.instance_variable_set(:@logger, nil)
      end

      it 'uses the custom logger' do
        expect(Lycra.configuration.logger).to eq(logger)
      end
    end

    context 'with default configuration' do
      before do
        Lycra.configuration.configure(logger: nil)
        Lycra.configuration.instance_variable_set(:@logger, nil)
      end

      it 'is an instance of Logger' do
        expect(Lycra.configuration.logger).to be_an_instance_of(::Logger)
      end

      it 'uses STDOUT' do
        expect(Lycra.configuration.logger.instance_variable_get(:@logdev).dev).to eq(STDOUT)
      end
    end
  end
end
