import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import SelectionController from "solid_stack_web/selection_controller"
import SparklineTooltipController from "solid_stack_web/sparkline_tooltip_controller"

const application = Application.start()
application.register("selection", SelectionController)
application.register("sparkline-tooltip", SparklineTooltipController)