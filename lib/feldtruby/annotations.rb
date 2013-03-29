module FeldtRuby

# A generic way to annotate Ruby objects/classes.
module Annotateable
  def _annotations
    @_annotations ||= Hash.new
  end
end

end