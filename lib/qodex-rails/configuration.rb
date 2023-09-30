module QodexRails
  class Configuration
    attr_accessor :collection_name, :api_key

    def initialize
      @collection_name = nil
      @api_key = nil
    end
  end
end
