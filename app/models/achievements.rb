class Achievements
  def self.slugify(input)
    input.downcase.gsub(/[^a-z0-9]+/, "-")
  end

  def self.slugs_for(group_name)
    @grouped ||= data.group_by {|x| x.fetch('group') }
    @grouped.fetch(slugify(group_name)).map {|x| x.fetch('slug') }
  end

  def self.data
    @data ||= JSON.parse(File.read("data/godzilla-achievements.json"))
  end
end
