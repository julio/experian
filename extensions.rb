unless Object.respond_to?(:blank?)
  class Object
    def blank?
      if respond_to?(:empty?) && respond_to?(:strip)
        empty? or strip.empty?
      elsif respond_to?(:empty?)
        empty?
      else
        !self
      end
    end
  end

  class NilClass
    def blank?
      true
    end
  end
end
