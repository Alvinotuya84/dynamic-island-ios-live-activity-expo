import type { StyleProp, ViewStyle } from "react-native";

export type TransitActivityPayload = {
  activityId: string;
  minutesRemaining: number;
};

export type DismissActivityPayload = {
  activityId: string;
};

export type TransitRouteInfo = {
  id: string;
  type: "bus" | "train" | "subway";
  number: string;
  destination: string;
  stops: string[];
};

export type ActivityModuleEvents = {
  onTransitActivityUpdate: (params: TransitActivityPayload) => void;
  onWidgetDismissTransitActivity: (params: DismissActivityPayload) => void;
};

export type ActivityViewProps = {
  route: TransitRouteInfo;
  currentStop: string;
  nextStop: string;
  estimatedMinutes: number;
  style?: StyleProp<ViewStyle>;
};
