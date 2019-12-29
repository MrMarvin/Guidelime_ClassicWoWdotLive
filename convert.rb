require 'json'
class Task
  def initialize()
    @index = nil
    @action = nil
    @race_specific = nil
    @class_specific = nil
    @class_specific_2 = nil
    #unknown
    @subject_id = nil
    @subject_count = nil
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
    @index, @action, @race_specific, @class_specific, @class_specific_2, _, @subject_id, @subject_count,  @subject_name, @target_name, @target_id, _, @coords, @zone, _, @requires, @comment = list_tingy
    self
  end

  def class_restriction
    class_names = {
      "L" => "Warlock",
      "W" => "Warrior",
      "M" => "Mage",
      "Pa" => "Paladin",
      "Pr" => "Priest",
      "R" => "Rogue",
      "S" => "Shaman",
      "D" => "Druid",
      "H" => "Hunter",
      "z" => "Cooking"
    }
    if @class_specific.empty?
      ""
    else
      applicable_classes = []
      class_names.each do |class_abbrv, class_name|
        applicable_classes << class_name if @class_specific.include?(class_abbrv)
      end
      if applicable_classes.include? "Cooking"
        " (#{applicable_classes.join(', ')} only)"
      else
        " [A #{applicable_classes.join(', ')}](#{applicable_classes.join(', ')} only)"
      end
    end
  end

  def race_restriction
    race_names = {
      "O" => "Orc",
      "T" => "Troll",
      "U" => "Undead",
      "C" => "Tauren",
      "H" => "Human",
      "D" => "Dwarf",
      "G" => "Gnome",
      "N" => "Nightelf"
    }
    if @race_specific.empty?
      ""
    else
      applicable_races = []
      race_names.each do |race_abbrv, race_name|
        applicable_races << race_name if @race_specific.include?(race_abbrv)
      end
      " [A #{applicable_races.join(', ')}](#{applicable_races.join(', ')} only)"
    end
  end

  def second_line_comment
    @comment.empty? ? "" : "\\\\*#{@comment.gsub('[','<').gsub(']','>')}*"
  end

  def action
    @action
  end

  def location
    return "" if coords.empty?
    if zone.empty?
      return "[G #{coords}]"
    else
      return "[G #{coords},#{zone}]"
    end
  end

  def zone
    @zone.split("-").map(&:capitalize).join(" ")
  end

  def subject_id
    @subject_id.empty? ? "" : " #{@subject_id.gsub('[','').gsub(']','')} "
  end

  def subject_count
    return "" if @subject_count.empty?
    "#{@subject_count}x"
  end

  def subject_name
    @subject_name.empty? ? "" : " #{subject_count}#{@subject_name.gsub('[','<').gsub(']','>')} "
  end

  def target_name
    "#{@target_name.gsub('[','<').gsub(']','>')}#{location}"
  end

  def coords
    "#{@coords.gsub('~','')}"
  end

  def qa
    return "" if subject_id.empty?
    "[QA#{subject_id} #{subject_name}]"
  end

  def qs
    return "" if subject_id.empty?
    "[QS#{subject_id} #{subject_name}]"
  end

  def qt
    return "" if subject_id.empty?
    "[QT#{subject_id} #{subject_name}]"
  end

  def qc
    return "" if subject_id.empty?
    "[QC#{subject_id} #{subject_name}]"
  end

  def xp
    min, max, level = @subject_name.match(/to (\d+) \/ (\d+) L(\d+)/)&.captures
    return "" unless min && max && level
    "[XP#{level}+#{min}]"
  end

  def to_s
    task_string = case @action
    when /DING/
      "DING [XP#{@action.gsub('DING','').strip}]"
    when /Accept Item Quest/
      "#{@action}#{qa} from #{target_name}"
    when /Pick Up/
      "#{@action}#{qa} from #{target_name}"
    when /Skip/
      "#{@action}#{qs} from #{target_name}"
    when /Hand In/
      "#{@action}#{qt} at #{target_name}"
    when /Complete Quest/
      "#{@action}#{qc}"
    when /Set Hearth/
      "[S] #{@action}#{subject_name}"
    when /Hearth/
      "[H] #{@action}#{subject_name}"
    when /Vendor/
      "#{@action} at [V]#{target_name}"
    when /Buy/
      "#{@action}#{subject_name}at [V]#{target_name}"
    when /Train/
      "[T] #{@action} #{subject_name}at #{target_name}"
    when /Fly/
      "Fly to [F #{subject_name.gsub('to','').gsub('The','').strip}]"
    when /Get Flight Path/
      "[P] #{@action}#{subject_name}at #{target_name}"
    when /Go/
      "#{location} #{@action}#{subject_name}"
    when /Grind/
      "#{action}#{location}#{subject_name}#{xp}"
    else
      "#{@action} #{subject_name}"
    end
    "#{task_string}#{class_restriction}#{race_restriction}#{second_line_comment}"
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
  def initialize(index, faction_name)
    @faction_filter_name = faction_name
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

  def min_level
    (@steps.map(&:tasks).flatten.select {|s| s.action.include? "DING"}.map {|s| s.action.gsub('DING','').strip.to_i }.min || 2) -1
  end

  def max_level
    @steps.map(&:tasks).flatten.select {|s| s.action.include? "DING"}.map {|s| s.action.gsub('DING','').strip.to_i }.max || 60
  end

  def to_s
    "Guidelime.registerGuide([[\n"+
    "[N #{name}]\n"+
    "[NX #{next_chapter_name}]\n"+
    "[GA #{@faction_filter_name}]\n"+
    "[D ClassicWoW.live Leveling Guide #{name} (#{min_level}-#{max_level}) converted to Guidelime by Marv]\n"+
    @steps.map(&:to_s).join("\n") +
    "\n]], \"ClassicWoW.live\")"
  end
end
class Guide
  attr_accessor :chapters
  def initialize(name)
    @name = name
    @chapters = []
  end

  def to_guidelime!
    chapters.each do |chapter|
      chapter.guide_name = @name
      File.open(chapter.name+ ".lua", 'w') do |f|
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
  leveling = JSON.parse(File.read(ARGV[0]))
  puts "Read #{name}"
  @guide = Guide.new(name)
  leveling.each do |group_index, steps|
    sg = Chapter.new(group_index, faction_name)
    steps.each do |step_index, tasks|
       step = Step.new(step)
       tasks.each do |task_as_list_thingy|
        task = Task.new
        step.tasks << task.parse_to_self!(task_as_list_thingy)
       end
       sg.steps << step
    end
    @guide.chapters << sg
  end

  @guide.to_guidelime!
end
