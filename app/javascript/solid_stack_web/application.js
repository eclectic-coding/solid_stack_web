import "@hotwired/turbo"
import { Application } from "@hotwired/stimulus"
import FilterPersistController from "solid_stack_web/filter_persist_controller"
import RefreshController from "solid_stack_web/refresh_controller"
import SearchController from "solid_stack_web/search_controller"
import SelectionController from "solid_stack_web/selection_controller"
import SparklineTooltipController from "solid_stack_web/sparkline_tooltip_controller"
import ThemeController from "solid_stack_web/theme_controller"
import TimestampController from "solid_stack_web/timestamp_controller"

const application = Application.start()
application.register("filter-persist", FilterPersistController)
application.register("refresh", RefreshController)
application.register("search", SearchController)
application.register("selection", SelectionController)
application.register("sparkline-tooltip", SparklineTooltipController)
application.register("theme", ThemeController)
application.register("timestamp", TimestampController)