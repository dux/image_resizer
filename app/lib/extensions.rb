# uncodes and decodes resized image URLs

class NilClass
  def blank?
    true
  end
end

###

class String
  def resized opts=nil
    opts ||= {}
    opts[:i] = self

    RackImageResizer.get opts
  end
end
