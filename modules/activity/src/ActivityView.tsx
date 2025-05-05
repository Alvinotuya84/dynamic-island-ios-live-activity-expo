import { requireNativeView } from 'expo';
import * as React from 'react';

import { ActivityViewProps } from './Activity.types';

const NativeView: React.ComponentType<ActivityViewProps> =
  requireNativeView('Activity');

export default function ActivityView(props: ActivityViewProps) {
  return <NativeView {...props} />;
}
