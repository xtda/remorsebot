module Bot
  class Music < Plugin
    require 'open3'

    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer

    class AutoPlaylist < Sequel::Model
      def self.find_song(search_term)
        first(search: search_term)
      end

      def self.find_or_create_song(search_term, title, filename)
        first(search: search_term) || create(search: search_term)
      end

      def self.create_song(search_term, title, filename)
        create(search: search_term, title: title, filename: filename)
      end

      def self.update_song(search_term, title, filename)
        where(search: search_term).update(title: title, filename: filename)
      end

      def self.random_song
        total_songs = AutoPlaylist.count
        limit(1, SecureRandom.random_number(total_songs)).first
      end
    end

    def self.about
      { name: 'Music Bot',
        author: 'xtda',
        version: '0.0.1' }
    end

    def self.init
      @currently_playing = nil
      @paused = false
      load_autoplaylist
    end

    def self.current_queue
      @queue ||= @queue = []
    end

    def self.black_list
      @black_list ||= @black_list = []
    end

    command :test do |_event, search|
      puts AutoPlaylist.random_song.search
    end

    command :join, help_available: false,
                   permission_level: Configuration.data['musicbot_join_permission'].to_i,
                   permission_message: false,
                   channels: Configuration.data['musicbot_channel_ids'] do |event|

      return if blacklisted? event.user.name
      join_channel(event)
    end

    command %i[leave byefelicia dismiss bye],
            help_available: false,
            channels: Configuration.data['musicbot_channel_ids'] do |event|

      return if blacklisted? event.user.name
      leave_channel(event)
    end

    command :queue, help_available: false,
                    channels: Configuration.data['musicbot_channel_ids'] do |event|
      queue(event)
    end

    command %i[np nowplaying playing],
            help_available: false,
            channels: Configuration.data['musicbot_channel_ids'] do |event|
      now_playing(event)
    end

    command :remove,
            help_available: false,
            channels: Configuration.data['musicbot_channel_ids'] do |event, id|
      return if blacklisted? event.user.name
      remove(event, id)
    end

    command :pause,
            help_available: false,
            channels: Configuration.data['musicbot_channel_ids'] do |event|
      return if blacklisted? event.user.name
      pause_music(event)
    end

    command :random,
            help_available: false,
            channels: Configuration.data['musicbot_channel_ids'] do |event|
      return if blacklisted? event.user.name

      reply = event.respond 'playing random song'
      delete_message(event.message, reply, 30)
      play(event)
    end

    command :autolist, help_available: false do
      puts autoplaylist
    end

    command :skip,
            help_available: false,
            permission_level: Configuration.data['musicbot_skip_permission'].to_i,
            permission_message: false do |event|
      return if blacklisted? event.user.name

      skip(event)
    end

    command :volume,
            help_available: false,
            channels: Configuration.data['musicbot_channel_ids'] do |event, vol|
      return if blacklisted? event.user.name

      set_volume(event, vol)
    end

    command :blacklist,
            min_args: 0, max_args: 1,
            help_available: false,
            permission_level: Configuration.data['musicbot_blacklist_permission'].to_i,
            permission_message: false do |event, name|
      blacklist(event, name)
    end

    def self.blacklisted?(name)
      return true if black_list.include? name.downcase
    end

    command :play, description: 'Add a song to queue',
                   usage: '!play <link to youtube video> or search string',
                   permission_level: Configuration.data['musicbot_play_permission'].to_i,
                   permission_message: false,
                   channels: Configuration.data['musicbot_channel_ids'] do |event, *args|
      return if blacklisted? event.user.name
      search = args.join(' ')
      return temp_message(event, 'I am not currently on any channel type !join to make me join', 15) unless event.voice
      find_video(event, search)
    end

    def self.join_channel(event)
      return temp_message(event, 'You are not in any voice channel', 15) unless event.user.voice_channel
      begin
        event.bot.voice_connect(event.user.voice_channel)
        reply = event.respond "Connected to voice channel: #{event.user.voice_channel.name}"
        delete_message(event.message, reply, 15)
      rescue StandardError => e
        puts "[ERROR] #{e.message}"
      end
    end

    def self.leave_channel(event)
      @currently_playing = nil
      @paused = false
      event.voice.destroy
      event.bot.game = nil
      temp_message(event, 'left channel', 15)
    end

    def self.download_song(url, path)
      url.include?('https://www.youtube.com/') ? search = "#{url}" : search = "ytsearch:\"#{url}\""
      opus_cmd = "#{Configuration.data['youtube_dl_location']} -o './#{path}/%(title)s.%(ext)s' --audio-format 'mp4' --format 'bestaudio[ext=m4a]/best' --no-color --no-progress --no-playlist --print-json --restrict-filenames -q --no-warnings -i --no-playlist #{search}"
      Open3.popen3(opus_cmd) do |_stdin, stdout, stderr, wait_thr|
        if wait_thr.value.success?
          song = JSON.parse(stdout.read.to_s, symbolize_names: true)
          dca_cmd2 = "ffmpeg -threads 0 -y -loglevel 0 -i #{song[:_filename]} -f s16le -ar 48000 -b:a 192K -vn #{song[:_filename]}.raw"
          Open3.popen3(dca_cmd2) do |_stdin, _stdout, _stderr, dca_wait_thr|
            FileUtils.rm(song[:_filename]) if dca_wait_thr.value.success?
          end
          return song
        end
      end
    end

    def self.find_video(event, url)
      song = download_song(url, 'tmp')
      data = { title: song[:title], filename: "#{song[:_filename]}.raw",
               added_by: event.user.name }
      current_queue.push(data)
      temp_message(event, "Added **#{data[:title]}** to the queue.", 20)
      play(event) unless @currently_playing
    end

    def self.skip(event)
      event.bot.game = nil
      event.voice.stop_playing
      temp_message(event, 'Skipped song', 20)
    end

    def self.queue(event)
      @currently_playing ? response = "Now playing: **#{@currently_playing[:title]}** added by #{@currently_playing[:added_by]}" : response =  'Now playing: (nothing)'
      response = "#{response}\nCurrent queue: \n"
      i = 1
      current_queue.each do |song|
        response = "#{response}#{i}. **#{song[:title]}** added by #{song[:added_by]}\n"
        i += 1
      end
      temp_message(event, response, 20)
      nil
    end

    def self.now_playing(event)
      @currently_playing ? response = "Now playing: **#{@currently_playing[:title]}** added by #{@currently_playing[:added_by]}" : response =  'Now playing: (nothing)'
      temp_message(event, response, 20)
    end

    def self.remove(event, number)
      if number == 'all'
        self.current_queue = []
      else
        temp_message(event, "Removed song #{current_queue.at(-1)[:title]}", 20)
        current_queue.delete_at(number.to_i - 1) unless number.to_i == -1
      end
      nil
    end

    def self.play(event)
      if @paused
        event.voice.continue
        event.bot.game = @currently_playing[:title]
        @paused = false
        return
      end
      loop do
        current_queue.length.zero? ? song = random_song : song = current_queue.shift
        @currently_playing = song
        event.bot.game = song[:title]
        music_thread = Thread.new { event.voice.play(open(song[:filename])) }
        music_thread.join
        break if event.voice.nil?
      end
    end

    def self.pause_music(event)
      if !@paused
        event.voice.pause
        @paused = true
        event.bot.game = "[paused] #{@currently_playing[:title]}"
      else
        event.voice.continue
        @paused = false
        event.bot.game = @currently_playing[:title]
      end
      delete_message(event.message, 20)
      nil
    end

    def self.set_volume(event, vol)
      return event.respond 'I am not currently on any channel type !join to make me join' unless event.voice
      if (vol.to_f >= 0) && (vol.to_f <= 100)
        event.voice.volume = vol.to_f / 100
        reply = "Volume set to #{(event.voice.volume * 100).to_i}"
      end
      temp_message(event, reply, 20)
      nil
    end

    def self.random_song
      song = AutoPlaylist.random_song
      if !song.filename.nil? && File.exist?(song.filename)
        data = { title: song.title, filename: song.filename,
                 added_by: 'autoplaylist' }
      else
        new_song = download_song(song.search, 'auto')
        AutoPlaylist.update_song(song.search, new_song[:title], "#{new_song[:_filename]}.raw",)
        data = { title: new_song[:title], filename: "#{new_song[:_filename]}.raw",
                 added_by: 'autoplaylist' }
      end
      data
    end

    def self.blacklist(event, name)
      response = ' '
      if name
        name = name.downcase
        if blacklisted? name
          black_list.delete name
          response = "#{name} removed from blacklist"
        else
          black_list.push name
          response = "#{name} added to blacklist"
        end
      else
        response = "Black listed:\n"
        black_list.each do |key|
          response += "#{key}\n"
        end
      end
      temp_message(event, response, 15)
    end

    def self.load_autoplaylist
      File.open('config/autoplaylist.txt').each do |line|
        AutoPlaylist.find_or_create_song(line, nil, nil)
      end
    end
  end
end
