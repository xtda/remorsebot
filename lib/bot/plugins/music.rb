module Bot
  class Music < Plugin
    require 'open3'

    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer

    def self.about
      { name: 'Music Bot',
        author: 'xtda',
        version: '0.0.1' }
    end

    def self.init
      @currently_playing = nil
      @paused = false
      @black_list = []
      load_autoplaylist
    end

    def self.current_queue
      @queue ||= @queue = []
    end

    def self.autoplaylist
      @autoplaylist ||= @autoplaylist = []
    end

    command :join, help_available: false,
                   permission_level: Configuration.data['musicbot_join_permission'].to_i,
                   permission_message: false do |event|

      return if blacklisted? event.user.name
      join_channel(event)
    end

    command [:leave, :byefelicia, :dismiss, :bye], help_available: false do |event|
      return if blacklisted? event.user.name
      leave_channel(event)
    end

    command :queue, help_available: false do |event|
      queue(event)
    end

    command :remove, help_available: false do |event, id|
      return if blacklisted? event.user.name
      remove(event, id)
    end

    command :pause, help_available: false do |event|
      return if blacklisted? event.user.name
      pause_music(event)
    end

    command :random, help_available: false do |event|
      play(event)
    end

    command :test, help_available: false do |event, filename|
      event.voice.play_dca("./tmp/#{filename}")
    end

    command :autolist, help_available: false do
      puts autoplaylist
    end
    
    command :blacklist,
            min_args: 0, max_args: 1,
            help_available: false,
            permission_level: Configuration.data['musicbot_blacklist_permission'].to_i,
            permission_message: false do |event, name|
      response = ' '

      if name
        name = name.downcase
        if blacklisted? name
          @black_list.delete name
          response = "#{name} removed from blacklist"
        else
          @black_list.push name
          response = "#{name} added to blacklist"
        end
      else
        response = "Black listed:\n"
        @black_list.each do |key|
          response += "#{key}\n"
        end
      end
      event.respond response
    end

    def self.blacklisted?(name)
      return true if @black_list.include? name.downcase
    end

    command :skip, help_available: false,
                   permission_level: Configuration.data['musicbot_skip_permission'].to_i,
                   permission_message: false do |event|
      skip(event)
    end

    command :volume, help_available: false do |event, vol|
      return if blacklisted? event.user.name
      set_volume(event, vol)
    end

    command :play, description: 'Add a song to queue',
                   usage: '!play <link to youtube video> or search string',
                   permission_level: Configuration.data['musicbot_play_permission'].to_i,
                   permission_message: false do |event, *args|
      return if blacklisted? event.user.name
      search = args.join(' ')
      return event.respond 'I am not currently on any channel type !join to make me join' unless event.voice
      if @paused
        play(event)
      else
        find_video(event, search)
      end
    end

    def self.join_channel(event)
      return event.respond 'You are not in any voice channel' unless event.user.voice_channel

      begin
        event.bot.voice_connect(event.user.voice_channel)
        "Connected to voice channel: #{event.user.voice_channel.name}"
      rescue StandardError => e
        puts "[ERROR] #{e.message}"
      end
    end

    def self.leave_channel(event)
      event.voice.destroy
      event.bot.game = ' '
      event.respond 'Left channel'
    end

    def self.find_video(event, url)
      url.include?('https://www.youtube.com/') ? search = "#{url}" : search = "ytsearch:\"#{url}\""
      opus_cmd = "#{Configuration.data['youtube_dl_location']} -x -o './tmp/%(title)s.m4a' --audio-format 'm4a' --no-color --no-progress --no-playlist --print-json -f bestaudio/best --restrict-filenames -q --no-warnings -i --no-playlist #{search}"
      Open3.popen3(opus_cmd) do |_stdin, stdout, _stderr, wait_thr|
        if wait_thr.value.success?
          song = JSON.parse(stdout.read.to_s, symbolize_names: true)
          dca_cmd = "./vendor/dca-rs --i #{song[:_filename]} > #{song[:_filename]}.dca"
          Open3.popen3(dca_cmd) do |_stdin, _stdout, _stderr, dca_wait_thr|
            if dca_wait_thr.value.success?
              FileUtils.rm(song[:_filename])
            end
          end
          data = { title: song[:title], filename: "#{song[:_filename]}.dca",
                   added_by: event.user.name }
          current_queue.push(data)
          event.respond "Added **#{data[:title]}** to the queue."
          puts data
        end
      end
      play(event) unless @currently_playing
    end

    def self.skip(event)
      event.respond 'Skipping song'
      event.voice.stop_playing
    end

    def self.queue(event)
      @currently_playing ? response = "Now playing: **#{@currently_playing[:title]}** added by #{@currently_playing[:added_by]}" : response =  'Now playing: (nothing)'
      response = "#{response}\nCurrent queue: \n"
      i = 1
      current_queue.each do |song|
        response = "#{response}#{i}. **#{song[:title]}** added by #{song[:added_by]}\n"
        i += 1
      end
      event.respond response
    end

    def self.remove(event, number)
      if number == 'all'
        self.current_queue = []
      else
        queue.delete_at(number.to_i - 1) unless number.to_i == -1
        event.respond 'Removed song'
      end
    end

    def self.play(event)
      if @paused
        event.voice.continue
        event.bot.game = "#{@currently_playing[:title]}"
        @paused = false
        return
      end
      loop do
        current_queue.length.zero? ? song = random_song : song = current_queue.shift
        @currently_playing = song
        event.bot.game = "#{song[:title]}"
        event.voice.play_dca(song[:filename])
      end
      @currently_playing = nil
      @paused = false
      event.bot.game = ' '
      event.respond 'queue empty'
    end

    def self.pause_music(event)
      if !@paused
        event.voice.pause
        @paused = true
        event.bot.game = "[paused] #{@currently_playing[:title]}"
      else
        event.voice.continue
        @paused = false
        event.bot.game = "#{@currently_playing[:title]}"
      end
      nil
    end

    def self.set_volume(event, vol)
      return event.respond 'I am not currently on any channel type !join to make me join' unless event.voice
      puts "Before: #{event.voice.filter_volume}"
      if (vol.to_f >= 0) && (vol.to_f <= 100)
        event.voice.filter_volume = vol.to_f / 100
      end
      puts "After: #{event.voice.filter_volume}"
      event.respond "Volume set to #{vol}"
    end

    def self.random_song
      song = autoplaylist.sample
      if song[:filename].nil?
        cmd = "#{Configuration.data['youtube_dl_location']} -x -o './tmp/%(title)s.m4a' --audio-format 'm4a' --no-color --no-progress --no-playlist --print-json -f bestaudio/best --restrict-filenames -q --no-warnings -i --no-playlist ytsearch:\"#{song[:search]}\""
        Open3.popen3(cmd) do |_stdin, stdout, _stderr, wait_thr|
          if wait_thr.value.success?
            parsed_song = JSON.parse(stdout.read.to_s, symbolize_names: true)
            dca_cmd = "./vendor/dca-rs --i #{parsed_song[:_filename]} > #{parsed_song[:_filename]}.dca"
            Open3.popen3(dca_cmd) do |_stdin, _stdout, _stderr, dca_wait_thr|
              if dca_wait_thr.value.success?
                FileUtils.rm(parsed_song[:_filename])
              end
            end
            song[:filename] = "#{parsed_song[:_filename]}.dca"
            song[:title] = parsed_song[:title]
            data = { title: parsed_song[:title], filename: "#{parsed_song[:_filename]}.dca",
                     added_by: 'autoplaylist' }
            data
          end
        end
      else
        data = { title: song[:title], filename: song[:filename],
                 added_by: 'autoplaylist' }
        data
      end
    end

    def self.load_autoplaylist
      File.open('config/samplelist.txt').each do |line|
        autolist = { search: line, title: nil, filename: nil }
        autoplaylist.push(autolist)
      end
    end
  end
end
