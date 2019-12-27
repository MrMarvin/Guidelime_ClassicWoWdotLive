require 'json'
CLASS_NAMES_TO_ABBRV = {
  "Warlock" => 'L',
  "Warrior" => "W",
  "Mage" => "M",
  "Paladin" => "Pa",
  "Priest" => "Pr",
  "Rogue" => "R",
  "Shaman" => "S",
  "Druid" => "D",
  "Hunter" => "H"
}

class Task
  def initialize(class_name)
    @class_filter_name = class_name

    @index = nil
    @action = nil
    @race_specific = nil
    @class_specific = nil
    @class_specific_2 = nil
    #unknown
    @subject_id = nil
    #unknown
    @subject_name = nil
    @target_name = nil
    @target_id = nil
    #unknown
    @coords = nil
    @zone = nil
    #unknown
    @requires = nil
    @comment = nil
  end

  def parse_to_self!(list_tingy)
    @index, @action, @race_specific, @class_specific, @class_specific_2, _, @subject_id, _,  @subject_name, @target_name, @target_id, _, @coords, @zone, _, @requires, @comment = list_tingy
    if @class_specific.include?(@class_filter_name) or @class_specific.empty?
      self
    else
      nil
    end
  end

  def class_restriction
    class_names = {
      "L" => "Warlock",
      "w" => "Warrior",
      "M" => "Mage",
      "Pa" => "Paladin",
      "Pr" => "Priest",
      "R" => "Rogue",
      "S" => "Shaman",
      "D" => "Druid",
      "H" => "Hunter"
    }
    if @class_specific.empty?
      ""
    else
      applicable_classes = []
      class_names.each do |class_abbrv, class_name|
        applicable_classes << class_name if @class_specific.include?(class_abbrv)
      end
      " (#{applicable_classes.join(', ')} only)"
    end
  end
  def race_restriction
    race_names = {
    # TODO
    }
    if @race_specific.empty?
      ""
    else
      applicable_races = []
      race_names.each do |race_abbrv, race_name|
        applicable_races << race_name if @race_specific.include?(race_abbrv)
      end
      " (#{applicable_races.join(', ')} only)"
    end
  end

  def to_s
    task_string = case @action
    when /Pick Up/
      "#{@action} [QA#{@subject_id} #{@subject_name}] from #{@target_name}"
    when /Hand In/
      "#{@action} [QT#{@subject_id} #{@subject_name}] at #{@target_name}"
    when /Complete Quest/
      "#{@action} [QC#{@subject_id} #{@subject_name}]"
    when /Set Hearth/
      "#{@action} [S] #{@subject_name.gsub('[','<').gsub(']','>')}"
    when /Vendor/
      "#{@action} at #{@target_name.gsub('[','<').gsub(']','>')}"
    else
      "#{@action} #{@subject_name.gsub('[','<').gsub(']','>')}"
    end
    "#{task_string}#{class_restriction}#{race_restriction}"
  end
end
class Step
  attr_accessor :tasks
  def initialize(index)
    @index = index
    @tasks = []
  end

  def to_s
    @tasks.map(&:to_s).join("\n")
  end
end
class Chapter
  attr_accessor :steps, :guide_name
  attr_reader :index
  def initialize(index, faction_name, class_name)
    @faction_filter_name = faction_name
    @class_filter_name = class_name
    @index = index
    @steps = []
    @guide_name = nil
  end

  def name
    "#{@guide_name} (Chapter #{format("%02d", index)})"
  end

  def next_chapter_name
    "#{@guide_name} (Chapter #{format("%02d", index.to_i+1)})"
  end


  def to_s
    "Guidelime.registerGuide([[\n"+
    "[N #{name}]\n"+
    "[NX #{next_chapter_name}]\n"+
    "[GA #{@faction_filter_name},#{@class_filter_name}]\n"+
    "[D ClassicWoW.live Leveling Guide for #{@name} converted to Guidelime by Marv]\n"+
    @steps.map(&:to_s).join("\n") +
    "\n]], \"ClassicWoW.live\")"
  end
end
class Guide
  attr_accessor :chapters
  def initialize(name, class_name)
    @name = name
    @class_name = class_name
    @chapters = []
  end

  def to_guidelime!
    chapters.each do |chapter|
      chapter.guide_name = @name+"_"+@class_name
      File.open("Guidelime_ClassicWoWdotLive_#{@class_name}/"+chapter.name+ ".lua", 'w') do |f|
        f.write(chapter.to_s)
      end
    end
  end
end

if ARGV[0]
  name = ARGV[0].split('.')[0]
  faction_name = case name
  when /Alliance/
    "Alliance"
  when /Horde/
    "Horde"
  end
  class_name = ARGV[1].chomp
  leveling = JSON.parse(File.read(ARGV[0]))
  puts "Read #{name}"
  @guide = Guide.new(name, class_name)
  leveling.each do |group_index, steps|
    sg = Chapter.new(group_index, faction_name, class_name)
    steps.each do |step_index, tasks|
       step = Step.new(step)
       tasks.each do |task_as_list_thingy|
        task = Task.new(CLASS_NAMES_TO_ABBRV[class_name])
        step.tasks << task if task.parse_to_self!(task_as_list_thingy)
       end
       sg.steps << step
    end
    @guide.chapters << sg
  end

  @guide.to_guidelime!
end
