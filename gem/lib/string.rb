unless ''.respond_to?(:resized)
  class ::String
    def resized opts=nil
      opts ||= {}
      opts[:i] = self

      RackImageResizer.get opts
    end
  end
end
