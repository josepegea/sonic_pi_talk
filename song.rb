eval_file "/Users/jes/Content/MadridRB/Talks/2022-10-25-SonicPi/music/my_pi.rb"

# Global timer

song_tick = 0.125

song = {
  riff:         mbr("**--------"),
  drums:        mbr("-***--**--"),
  bass:         mbr("--**--**--"),
  strings:      mbr("--**--**--"),
  chorus_drums: mbr("----**--**"),
  chorus_bass:  mbr("----**--**"),
  solo:         mbr("------**--")
}

$controller = MyPi::SongController.new(tick_name: :quarter_pulse, tick_time: song_tick, song_parts: song)

$controller.run(0)

# Drums

drum_patterns = {
  drum_bass_hard:  mbr("*-|"),
  drum_snare_hard: mbr("--*-|--*-|--*-|-*-*|")
}

sample_pattern_song_live_loop :drums, sync: :verse, wait_on: :half_pulse, sample_patterns: drum_patterns


# Chorus drums

chorus_drum_patterns = {
  drum_bass_hard:   mbr("-**-|--**|"),
  drum_snare_hard:  mbr("*--*|----|"),
  drum_splash_hard: mbr("*--*|----|")
}

sample_pattern_song_live_loop :chorus_drums, sync: :verse, wait_on: :half_pulse, sample_patterns: chorus_drum_patterns

# Bass line

chord_values = [[:D3], [:C3], [:G3], [:D3]].ring

chords = chord_values.map { |c| c.length > 1 ? c : [c.first, :major] }.map { |c| chord(*c) }.ring

chords_idx = 0

with_fx :echo, phase: 0.5 do
  with_fx :reverb, room: 1 do
    song_live_loop :bass, sync: :verse, wait_on: :pulse do
      use_synth :bass_foundation
      chord_notes = chords[chords_idx / 8]
      play chord_notes.pick
      chords_idx += 1
    end
  end
end

# Chorus Bass line

chorus_chord_values = [[:A2], [:C2], [:D2], [:D2],
                       [:A2], [:C2], [:D2], [:D2],
                       [:A2], [:C2], [:D2], [:D2],
                       [:A2], [:C2], [:E2], [:E2]].ring

chorus_chords = chorus_chord_values.map { |c| c.length > 1 ? c : [c.first, :major] }.map { |c| chord(*c) }.ring

chorus_chords_idx = 0

with_fx :echo, phase: 0.5 do
  with_fx :reverb, room: 1 do
    song_live_loop :chorus_bass, sync: :verse, wait_on: :pulse do
      use_synth :bass_foundation
      chorus_chord_notes = chorus_chords[chorus_chords_idx / 4]
      play chorus_chord_notes
      chorus_chords_idx += 1
    end
  end
end

# Strings

string_chord_values = [:D4, :C4, :G3, :D4].ring

string_chords = string_chord_values.map { |c| chord(c, :major) }.ring

song_live_loop :strings, sync: :verse, wait_on: :chord do
  use_synth :zawa
  chord_notes = string_chords.tick
  play chord_notes, amp: 1, range: 10, phase: 2, attack: 1, sustain: song_tick * 30
end

# Riff

riff_notes = [:g5, :a5, :fs6, :a5, :g5, :a5, :d6, :a5].ring

with_fx :distortion, distort: 0.7 do
  song_live_loop :riff, sync: :verse, wait_on: :half_pulse do
    use_synth :supersaw
    play riff_notes.tick, amp: 0.3, note_slide: song_tick, mod_range: 0.1, mod_phase: 1, detune: 0.3, depth: 10, divisor: 2
  end
end

# Solo

solo = [[:g5, 6], [:fs5, 8], [:a5, 2],
        [:g5, 6], [:fs5, 8], [:a5, 2],
        [:g5, 6], [:e5, 8], [:a5, 2],
        [:g5, 6], [:e5, 8], [:a5, 2],
        [:g5, 10], [:b5, 2], [:a5, 2], [:g5, 2],
        [:b5, 2], [:a5, 2], [:g5, 2], [:b5, 6], [:a5, 2], [:g5, 2],
        [:fs5, 2], [:e5, 2], [:g4, 2], [:g5, 10],
        [:fs5, 2], [:e5, 2], [:g4, 2], [:g5, 10]
       ].ring;

song_live_loop :solo, sync: :verse, wait_on: :pulse, dont_wait_after_block: true do
  use_synth :supersaw
  note, duration = solo.tick
  play note, amp: 1, note_slide: song_tick, mod_range: 0.1, mod_phase: 1, detune: 0.3, depth: 10, divisor: 2
  sleep duration * song_tick
end


# Free playing

# Keyboard

manual_beats = {
  48 => :drum_bass_hard,
  50 => :drum_snare_hard,
  52 => :drum_splash_hard
}

in_thread do
  loop do
    use_real_time
    note, velocity = sync "/midi:lpk25:1/note_on"
    if manual_beats[note]
      sample manual_beats[note]
    else
      synth :piano, note: note, amp: velocity / 127.0
    end
  end
end

# Guitar

# with_fx :lpf, cutoff: 115 do
#   with_fx :distortion, distort: 0.99 do
#     live_audio :guitar, input: 1, amp: 1
#   end
# end
