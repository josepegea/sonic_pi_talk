$sonic_pi = self

def make_bool_array(pattern)
  pattern
    .chars
    .reject { |c| c == '|' }
    .map { |c| c == '*' }
end

alias mba make_bool_array

def make_bool_ring(pattern)
  make_bool_array(pattern).ring
end

alias mbr make_bool_ring

def song_live_loop(*args, **kwargs)
  name = args.first
  wait_on = kwargs.delete(:wait_on)
  dont_wait_after_block = kwargs.delete(:dont_wait_after_block)
  live_loop(*args, **kwargs) do
    call_block = $controller.song_part?(name)
    yield if call_block
    sync wait_on unless call_block && dont_wait_after_block
  end
end

def sample_pattern_song_live_loop(*args, **kwargs)
  sample_patterns = kwargs.delete(:sample_patterns)
  sample_idx = 0
  song_live_loop(*args, **kwargs) do
    sample_patterns.each do |sample_key, pattern|
      sample sample_key if pattern[sample_idx]
    end
    sample_idx += 1
  end
end

module MyPi
  DEFAULT_TIME_PARTS = {
    half_pulse: 2,
    pulse: 2,
    bar: 4,
    chord: 2,
    verse: 4
  }

  class SongController < Object
    attr_accessor :time_parts, :song_parts, :tick_name, :tick_time

    def initialize(time_parts: DEFAULT_TIME_PARTS, song_parts:, tick_name:, tick_time:)
      @time_parts = time_parts
      @song_parts = song_parts
      @tick_name = tick_name
      @tick_time = tick_time
      @total_ticks = time_parts.values.reduce(1, &:*)
    end

    def run(start_part = 0)
      @idx = start_part * @total_ticks
      $sonic_pi.live_loop @tick_name, delay: 1 do
        $sonic_pi.cue @tick_name
        @time_parts.keys.reduce(1) do |mult, part_name|
          mult *= @time_parts[part_name]
          $sonic_pi.cue part_name if @idx % mult == 0
          mult
        end
        $sonic_pi.sleep @tick_time
        @idx += 1
      end
    end

    def song_part?(part)
      @song_parts[part][@idx  / @total_ticks]
    end
  end
end
