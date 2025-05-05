import { NativeModule, requireNativeModule } from "expo";

import { ActivityModuleEvents } from "./Activity.types";

declare class ActivityModule extends NativeModule<ActivityModuleEvents> {
  // Start a Live Activity for transit tracking
  startActivity(
    transitMode: string,
    routeNumber: string,
    destination: string,
    nextStation: string,
    currentStation: string,
    estimatedMinutes: number,
    delayMinutes: number
  ): Promise<string>;

  // Update an existing Live Activity with new transit info
  updateActivity(
    activityId: string,
    nextStation: string,
    currentStation: string,
    estimatedMinutes: number,
    delayMinutes: number
  ): Promise<boolean>;

  // End a specific Live Activity
  endActivity(activityId: string): Promise<boolean>;

  // End all Live Activities
  endAllActivities(): Promise<boolean>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ActivityModule>("Activity");
