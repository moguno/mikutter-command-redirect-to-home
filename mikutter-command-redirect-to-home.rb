# coding: UTF-8

Plugin.create(:mikutter_command_redirect_to_home) {
  @messages = []
  if !UserConfig[:redirect_timer] 
    UserConfig[:redirect_timer] ||= 10
  end

  # 繰り返しReserverを呼ぶ
  module Looper
    def self.start(timer_set, &proc)
      proc.call

      Reserver.new(timer_set.call) {
        start(timer_set, &proc)
      }
    end
  end

  # メッセージを1つ取り出す
  def fetch_message!()
    if @messages.length == 0
      return nil
    end

    # 最旧のメッセージを取り出す
    message = @messages.sort { |_| _[:created].to_i }[0]
    @messages.delete(message)

    message
  end

  settings("リダイレクト") {
    adjustment("混ぜ込み周期（秒）", :redirect_timer, 1, 10000000)
  }

  on_boot { |service|
    Looper.start(-> { UserConfig[:redirect_timer] }) {
      message = fetch_message!

      if message
        Delayer.new {
          Plugin::GUI::Timeline.cuscaded[:home_timeline] << message
          if message[:modified] <= Time.now
            message[:modified] = Time.now
            Plugin::call(:message_modified, message)
          end
        }
      end
    }
  }

  command(:redirect_to_home,
          :name => _("ホームタイムラインにリダイレクト"),
          :condition => lambda { |opt| Plugin::Command[:HasMessage] },
          :visible => false,
          :role => :timeline) { |opt|
    @messages += opt.messages
  }
}
