// Register all Raif controllers
import { application } from "controllers/application"

import ConversationsController from "sentinel/controllers/conversations_controller"
application.register("sentinel--conversations", ConversationsController)

export { ConversationsController }

import "sentinel/stream_actions/sentinel_scroll_to_bottom"

