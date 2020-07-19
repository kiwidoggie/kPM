class "Chat"

function Chat:__init()
    -- Check to see if dead chat is enabled (sending messages to non-dead players)
    self.m_DeadChatEnabled = false
end