class String
    # Convert to normal, iso formatted string. Skip invalid and undefined utf-8 sequences
    # in the conversion.
    def to_iso
        self.encode('ISO-8859-1', 'utf-8', :invalid => :replace, :undef => :replace)
    end
end