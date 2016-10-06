class StyleSectionRule < ActiveRecord::Base

	before_save :truncate_values
	def truncate_values
		['rule_type', 'rule_value'].each do |column|
			next if self[column].nil?
			length = StyleSectionRule.columns_hash[column].limit
			self[column] = self[column][0..length-1] if self[column].length > length
		end
	end

	def to_userjs_includes
		if rule_type == 'domain'
			return ["http://" + self.rule_value + "/*", "https://" + self.rule_value + "/*", "http://*." + self.rule_value + "/*", "https://*." + self.rule_value + "/*"]
		end
		if rule_type == 'url-prefix'
			return [self.rule_value + "*"]
		end
		if rule_type == 'url'
			return [self.rule_value]
		end
		#not supported on chrome
		#if rule_type == 'regexp'
		#	return ['/' + self.value + '/']
		#end
		return nil
	end

end
