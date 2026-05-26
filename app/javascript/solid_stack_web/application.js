import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import RefreshController from "solid_stack_web/refresh_controller"
import SearchController from "solid_stack_web/search_controller"
import SelectionController from "solid_stack_web/selection_controller"
import SparklineTooltipController from "solid_stack_web/sparkline_tooltip_controller"

const application = Application.start()
application.register("refresh", RefreshController)
application.register("search", SearchController)
application.register("selection", SelectionController)
application.register("sparkline-tooltip", SparklineTooltipController)