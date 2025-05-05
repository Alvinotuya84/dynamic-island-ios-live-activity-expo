import { GLView } from "expo-gl";
import React, { useEffect, useRef, useState } from "react";
import {
  Alert,
  Dimensions,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import * as THREE from "three";

import ActivityModule from "../../modules/activity";
import TransitStorage from "../../modules/activity/src/TransitStorage";

const { width, height } = Dimensions.get("window");

type TransitRouteInfo = {
  id: string;
  type: "bus" | "train" | "subway";
  number: string;
  destination: string;
  stops: string[];
};

const SAMPLE_ROUTES: TransitRouteInfo[] = [
  {
    id: "R1",
    type: "bus",
    number: "42",
    destination: "Downtown",
    stops: ["Central Park", "Main St", "City Hall", "Market Square"],
  },
  {
    id: "R2",
    type: "train",
    number: "7",
    destination: "Westside",
    stops: ["Union Station", "Tech Hub", "Financial District", "Garden Park"],
  },
  {
    id: "R3",
    type: "subway",
    number: "B",
    destination: "Airport",
    stops: ["Downtown", "CBD", "University", "Nairobi"],
  },
];

const APP_GROUP = "group.com.alvindo.transit-pulse-live.transitpulse";

export default function App() {
  const [activeRoute, setActiveRoute] = useState<TransitRouteInfo | null>(null);
  const [currentStopIndex, setCurrentStopIndex] = useState(0);
  const [liveActivityId, setLiveActivityId] = useState<string | null>(null);
  const [minutesRemaining, setMinutesRemaining] = useState(10);
  const [delayMinutes, setDelayMinutes] = useState(0);
  const [isTracking, setIsTracking] = useState(false);
  const [cameraRotation, setCameraRotation] = useState(0);

  const threeRef = useRef<{
    gl?: any;
    renderer?: THREE.WebGLRenderer;
    scene?: THREE.Scene;
    camera?: THREE.PerspectiveCamera;
    vehicleGroup?: THREE.Group;
    routePath?: THREE.Group;
  }>({});
  const animationRef = useRef<number | null>(null);

  useEffect(() => {
    const transitUpdateSubscription = ActivityModule.addListener(
      "onTransitActivityUpdate",
      ({ activityId, minutesRemaining }) => {
        setMinutesRemaining(minutesRemaining);
      }
    );

    const dismissSubscription = ActivityModule.addListener(
      "onWidgetDismissTransitActivity",
      ({ activityId }) => {
        handleStopTracking();
      }
    );

    const cameraIntervalId = setInterval(() => {
      setCameraRotation((prev) => (prev + 0.005) % (2 * Math.PI));
    }, 50);

    return () => {
      transitUpdateSubscription.remove();
      dismissSubscription.remove();
      clearInterval(cameraIntervalId);
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (
      isTracking &&
      activeRoute &&
      liveActivityId &&
      currentStopIndex < activeRoute.stops.length - 1
    ) {
      const moveIntervalId = setInterval(() => {
        if (minutesRemaining <= 0) {
          if (currentStopIndex < activeRoute.stops.length - 1) {
            const nextStopIndex = currentStopIndex + 1;
            setCurrentStopIndex(nextStopIndex);

            const newMinutesRemaining = 5 + Math.floor(Math.random() * 5);
            setMinutesRemaining(newMinutesRemaining);

            const newDelay =
              Math.random() > 0.8 ? Math.floor(Math.random() * 5) + 1 : 0;
            setDelayMinutes(newDelay);

            const nextStop =
              activeRoute.stops[
                nextStopIndex < activeRoute.stops.length - 1
                  ? nextStopIndex + 1
                  : nextStopIndex
              ];
            const currentStop = activeRoute.stops[nextStopIndex];

            ActivityModule.updateActivity(
              liveActivityId,
              nextStop,
              currentStop,
              newMinutesRemaining,
              newDelay
            );

            updateVehiclePosition(activeRoute, nextStopIndex);
          } else {
            handleStopTracking();
            Alert.alert("Arrived", "You have reached your destination!");
          }
        } else {
          setMinutesRemaining((prev) => Math.max(0, prev - 1));
        }
      }, 1000);

      return () => clearInterval(moveIntervalId);
    }
  }, [
    isTracking,
    activeRoute,
    liveActivityId,
    currentStopIndex,
    minutesRemaining,
  ]);

  const handleStartTracking = async () => {
    if (!activeRoute) {
      Alert.alert("Select a Route", "Please select a transit route first");
      return;
    }

    try {
      const currentStop = activeRoute.stops[currentStopIndex];
      const nextStop = activeRoute.stops[currentStopIndex + 1] || "Final Stop";
      const estimatedMinutes = 10;
      const randomDelay =
        Math.random() > 0.7 ? Math.floor(Math.random() * 5) + 1 : 0;
      setDelayMinutes(randomDelay);

      const id = await ActivityModule.startActivity(
        activeRoute.type,
        activeRoute.number,
        activeRoute.destination,
        nextStop,
        currentStop,
        estimatedMinutes,
        randomDelay
      );

      setLiveActivityId(id);
      setMinutesRemaining(estimatedMinutes);
      setIsTracking(true);

      const transitStorage = new TransitStorage(APP_GROUP);
      transitStorage.set("activeTransit", {
        routeType: activeRoute.type,
        routeNumber: activeRoute.number,
        destination: activeRoute.destination,
        currentStop,
        nextStop,
        estimatedMinutes,
        delayMinutes: randomDelay,
      });

      TransitStorage.reloadWidget();
    } catch (error) {
      console.error("Failed to start activity:", error);
      Alert.alert("Error", "Failed to start live activity");
    }
  };

  const handleStopTracking = async () => {
    if (liveActivityId) {
      await ActivityModule.endActivity(liveActivityId);
      setLiveActivityId(null);
    }
    setIsTracking(false);
  };

  const selectRoute = (route: TransitRouteInfo) => {
    setActiveRoute(route);
    setCurrentStopIndex(0);
    updateRouteVisualization(route);
  };

  const onContextCreate = async (gl: any) => {
    const { drawingBufferWidth: width, drawingBufferHeight: height } = gl;

    const renderer = new THREE.WebGLRenderer({
      context: gl,
      width,
      height,
      antialias: true,
    });

    renderer.setSize(width, height);
    renderer.setClearColor(0x1b2838);

    const scene = new THREE.Scene();

    const camera = new THREE.PerspectiveCamera(70, width / height, 0.01, 1000);
    camera.position.set(0, 5, 10);
    camera.lookAt(0, 0, 0);

    const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 10, 7.5);
    scene.add(directionalLight);

    const groundGeometry = new THREE.PlaneGeometry(30, 30);
    const groundMaterial = new THREE.MeshStandardMaterial({
      color: 0x333333,
      roughness: 0.8,
    });
    const ground = new THREE.Mesh(groundGeometry, groundMaterial);
    ground.rotation.x = -Math.PI / 2;
    ground.position.y = -0.5;
    scene.add(ground);

    const routePath = new THREE.Group();
    scene.add(routePath);

    const buildings = createBuildings();
    scene.add(buildings);

    const vehicleGroup = new THREE.Group();
    scene.add(vehicleGroup);

    threeRef.current = {
      gl,
      renderer,
      scene,
      camera,
      vehicleGroup,
      routePath,
    };

    const render = () => {
      if (
        !threeRef.current.renderer ||
        !threeRef.current.scene ||
        !threeRef.current.camera
      )
        return;

      const { scene, camera, renderer } = threeRef.current;

      if (camera) {
        const radius = 10;
        camera.position.x = Math.sin(cameraRotation) * radius;
        camera.position.z = Math.cos(cameraRotation) * radius;
        camera.lookAt(0, 0, 0);
      }

      renderer.render(scene, camera);
      gl.endFrameEXP();

      animationRef.current = requestAnimationFrame(render);
    };

    render();
  };

  const createBuildings = () => {
    const buildingsGroup = new THREE.Group();

    for (let i = 0; i < 20; i++) {
      const width = 1 + Math.random() * 2;
      const height = 2 + Math.random() * 10;
      const depth = 1 + Math.random() * 2;

      const geometry = new THREE.BoxGeometry(width, height, depth);
      const material = new THREE.MeshStandardMaterial({
        color: 0x808080 + Math.random() * 0x7f7f7f,
        roughness: 0.7 + Math.random() * 0.3,
      });

      const building = new THREE.Mesh(geometry, material);

      const gridSize = 15;
      building.position.x = Math.floor(Math.random() * gridSize) - gridSize / 2;
      building.position.z = Math.floor(Math.random() * gridSize) - gridSize / 2;
      building.position.y = height / 2;

      addWindowsToBuilding(building, width, height, depth);

      buildingsGroup.add(building);
    }

    return buildingsGroup;
  };

  const addWindowsToBuilding = (
    building: THREE.Mesh,
    width: number,
    height: number,
    depth: number
  ) => {
    const windowGeometry = new THREE.BoxGeometry(0.3, 0.3, 0.05);
    const windowMaterial = new THREE.MeshStandardMaterial({
      color: 0xffff99,
      emissive: 0xffff99,
      emissiveIntensity: 0.5,
    });

    const windowsPerFloor = Math.floor(width / 0.5);
    const floors = Math.floor(height / 0.8);

    for (let floor = 0; floor < floors; floor++) {
      for (let w = 0; w < windowsPerFloor; w++) {
        const window = new THREE.Mesh(windowGeometry, windowMaterial);
        window.position.x = (w - (windowsPerFloor - 1) / 2) * 0.5;
        window.position.y = (floor - height / 2 + 0.5) * 0.8;
        window.position.z = depth / 2 + 0.025;
        building.add(window);
      }
    }

    for (let floor = 0; floor < floors; floor++) {
      for (let w = 0; w < windowsPerFloor; w++) {
        const window = new THREE.Mesh(windowGeometry, windowMaterial);
        window.position.x = (w - (windowsPerFloor - 1) / 2) * 0.5;
        window.position.y = (floor - height / 2 + 0.5) * 0.8;
        window.position.z = -(depth / 2 + 0.025);
        building.add(window);
      }
    }
  };

  const createBus = (group: THREE.Group) => {
    const busBody = new THREE.Mesh(
      new THREE.BoxGeometry(2, 1, 4),
      new THREE.MeshStandardMaterial({ color: 0x4caf50 })
    );
    busBody.position.y = 0.5;

    const busWindows = new THREE.Mesh(
      new THREE.BoxGeometry(1.8, 0.5, 3.8),
      new THREE.MeshStandardMaterial({
        color: 0x87ceeb,
        transparent: true,
        opacity: 0.7,
      })
    );
    busWindows.position.y = 0.8;

    const wheelGeometry = new THREE.CylinderGeometry(0.3, 0.3, 0.2, 16);
    const wheelMaterial = new THREE.MeshStandardMaterial({ color: 0x000000 });

    const wheel1 = new THREE.Mesh(wheelGeometry, wheelMaterial);
    wheel1.rotation.z = Math.PI / 2;
    wheel1.position.set(-1.1, 0, 1);

    const wheel2 = wheel1.clone();
    wheel2.position.set(1.1, 0, 1);

    const wheel3 = wheel1.clone();
    wheel3.position.set(-1.1, 0, -1);

    const wheel4 = wheel1.clone();
    wheel4.position.set(1.1, 0, -1);

    group.add(busBody, busWindows, wheel1, wheel2, wheel3, wheel4);
  };

  const createTrain = (group: THREE.Group) => {
    const trainBody = new THREE.Mesh(
      new THREE.BoxGeometry(1.5, 1.2, 6),
      new THREE.MeshStandardMaterial({ color: 0x2196f3 })
    );
    trainBody.position.y = 0.6;

    const trainWindows = new THREE.Mesh(
      new THREE.BoxGeometry(1.4, 0.5, 5.8),
      new THREE.MeshStandardMaterial({
        color: 0x87ceeb,
        transparent: true,
        opacity: 0.7,
      })
    );
    trainWindows.position.y = 0.9;

    const wheelGeometry = new THREE.CylinderGeometry(0.3, 0.3, 0.2, 16);
    const wheelMaterial = new THREE.MeshStandardMaterial({ color: 0x000000 });

    const wheel1 = new THREE.Mesh(wheelGeometry, wheelMaterial);
    wheel1.rotation.z = Math.PI / 2;
    wheel1.position.set(-0.8, 0, 2);

    const wheel2 = wheel1.clone();
    wheel2.position.set(0.8, 0, 2);

    const wheel3 = wheel1.clone();
    wheel3.position.set(-0.8, 0, 0);

    const wheel4 = wheel1.clone();
    wheel4.position.set(0.8, 0, 0);

    const wheel5 = wheel1.clone();
    wheel5.position.set(-0.8, 0, -2);

    const wheel6 = wheel1.clone();
    wheel6.position.set(0.8, 0, -2);

    group.add(
      trainBody,
      trainWindows,
      wheel1,
      wheel2,
      wheel3,
      wheel4,
      wheel5,
      wheel6
    );
  };

  const createSubway = (group: THREE.Group) => {
    const subwayBody = new THREE.Mesh(
      new THREE.BoxGeometry(2, 1.5, 5),
      new THREE.MeshStandardMaterial({ color: 0xff9800 })
    );
    subwayBody.position.y = 0.75;

    const subwayWindows = new THREE.Mesh(
      new THREE.BoxGeometry(1.9, 0.6, 4.8),
      new THREE.MeshStandardMaterial({
        color: 0x87ceeb,
        transparent: true,
        opacity: 0.7,
      })
    );
    subwayWindows.position.y = 1.0;

    const headlight1 = new THREE.Mesh(
      new THREE.CircleGeometry(0.2, 16),
      new THREE.MeshStandardMaterial({
        color: 0xffff00,
        emissive: 0xffff00,
        emissiveIntensity: 0.5,
      })
    );
    headlight1.position.set(-0.5, 0.75, 2.51);
    headlight1.rotation.y = Math.PI;

    const headlight2 = headlight1.clone();
    headlight2.position.set(0.5, 0.75, 2.51);

    group.add(subwayBody, subwayWindows, headlight1, headlight2);
  };

  const updateRouteVisualization = (route: TransitRouteInfo) => {
    if (!threeRef.current.routePath || !threeRef.current.vehicleGroup) return;

    const { routePath, vehicleGroup } = threeRef.current;

    while (routePath.children.length > 0) {
      routePath.remove(routePath.children[0]);
    }

    const points = route.stops.map((_, index, array) => {
      const t = index / (array.length - 1);
      const x = (index - (array.length - 1) / 2) * 3;
      const z = Math.sin(t * Math.PI) * 5;
      return new THREE.Vector3(x, 0, z);
    });

    const curve = new THREE.CatmullRomCurve3(points);
    const geometry = new THREE.TubeGeometry(curve, 64, 0.2, 8, false);

    const material = new THREE.MeshStandardMaterial({
      color:
        route.type === "bus"
          ? 0x4caf50
          : route.type === "train"
          ? 0x2196f3
          : 0xff9800,
    });

    const tube = new THREE.Mesh(geometry, material);
    routePath.add(tube);

    points.forEach((point, index) => {
      const stationGeometry = new THREE.CylinderGeometry(0.3, 0.3, 0.1, 16);
      const stationMaterial = new THREE.MeshStandardMaterial({
        color: index === currentStopIndex ? 0xffc107 : 0xffffff,
      });
      const station = new THREE.Mesh(stationGeometry, stationMaterial);
      station.position.copy(point);
      station.position.y = 0.05;
      routePath.add(station);

      const signGeometry = new THREE.BoxGeometry(0.5, 0.5, 0.1);
      const signMaterial = new THREE.MeshStandardMaterial({
        color: 0xffffff,
        emissive: index === currentStopIndex ? 0x4caf50 : 0xffffff,
        emissiveIntensity: index === currentStopIndex ? 0.5 : 0.2,
      });
      const sign = new THREE.Mesh(signGeometry, signMaterial);
      sign.position.copy(point);
      sign.position.y = 1;
      routePath.add(sign);
    });

    while (vehicleGroup.children.length > 0) {
      vehicleGroup.remove(vehicleGroup.children[0]);
    }

    if (route.type === "bus") {
      createBus(vehicleGroup);
    } else if (route.type === "train") {
      createTrain(vehicleGroup);
    } else {
      createSubway(vehicleGroup);
    }

    vehicleGroup.position.copy(points[currentStopIndex]);
    vehicleGroup.position.y = 0.3;

    if (currentStopIndex < points.length - 1) {
      const nextPoint = points[currentStopIndex + 1];
      const direction = new THREE.Vector3().subVectors(
        nextPoint,
        points[currentStopIndex]
      );
      const angle = Math.atan2(direction.x, direction.z);
      vehicleGroup.rotation.y = angle;
    }
  };

  const updateVehiclePosition = (
    route: TransitRouteInfo,
    stopIndex: number
  ) => {
    if (!threeRef.current.vehicleGroup || !threeRef.current.routePath) return;

    const { vehicleGroup } = threeRef.current;

    const points = route.stops.map((_, index, array) => {
      const t = index / (array.length - 1);
      const x = (index - (array.length - 1) / 2) * 3;
      const z = Math.sin(t * Math.PI) * 5;
      return new THREE.Vector3(x, 0, z);
    });

    vehicleGroup.position.copy(points[stopIndex]);
    vehicleGroup.position.y = 0.3;

    if (stopIndex < points.length - 1) {
      const nextPoint = points[stopIndex + 1];
      const direction = new THREE.Vector3().subVectors(
        nextPoint,
        points[stopIndex]
      );
      const angle = Math.atan2(direction.x, direction.z);
      vehicleGroup.rotation.y = angle;
    }
  };

  const getRouteTypeColor = (type: string) => {
    switch (type) {
      case "bus":
        return "#4CAF50";
      case "train":
        return "#2196F3";
      case "subway":
        return "#FF9800";
      default:
        return "#FFFFFF";
    }
  };

  const getRouteTypeIcon = (type: string) => {
    switch (type) {
      case "bus":
        return "🚌";
      case "train":
        return "🚆";
      case "subway":
        return "🚇";
      default:
        return "🚶";
    }
  };

  // Key changes for making the app scrollable
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" />
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollViewContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Text style={styles.title}>Transit Pulse Tracker</Text>
        </View>
        <View style={styles.glContainer}>
          <GLView style={styles.gl} onContextCreate={onContextCreate} />
        </View>
        <View style={styles.controlsContainer}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.routeSelector}
          >
            {SAMPLE_ROUTES.map((route) => (
              <TouchableOpacity
                key={route.id}
                style={[
                  styles.routeButton,
                  { backgroundColor: getRouteTypeColor(route.type) },
                  activeRoute?.id === route.id && styles.activeRouteButton,
                ]}
                onPress={() => selectRoute(route)}
              >
                <Text style={styles.routeIcon}>
                  {getRouteTypeIcon(route.type)}
                </Text>
                <Text style={styles.routeNumber}>{route.number}</Text>
                <Text style={styles.routeDestination}>{route.destination}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
          {activeRoute && (
            <View style={styles.routeInfo}>
              <Text style={styles.routeInfoText}>
                Current Stop: {activeRoute.stops[currentStopIndex]}
              </Text>
              {currentStopIndex < activeRoute.stops.length - 1 && (
                <Text style={styles.routeInfoText}>
                  Next Stop: {activeRoute.stops[currentStopIndex + 1]}
                </Text>
              )}
              {isTracking && (
                <View style={styles.timeInfo}>
                  <Text style={styles.timeText}>
                    Arriving in: {minutesRemaining} min
                  </Text>
                  {delayMinutes > 0 && (
                    <Text style={styles.delayText}>
                      Delayed by {delayMinutes} min
                    </Text>
                  )}
                </View>
              )}
            </View>
          )}
          <View style={styles.actionButtons}>
            {!isTracking ? (
              <TouchableOpacity
                style={styles.startButton}
                onPress={handleStartTracking}
                disabled={!activeRoute}
              >
                <Text style={styles.buttonText}>Start Tracking</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity
                style={styles.stopButton}
                onPress={handleStopTracking}
              >
                <Text style={styles.buttonText}>Stop Tracking</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* Additional information section (optional) */}
        <View style={styles.infoSection}>
          <Text style={styles.sectionTitle}>Transit Information</Text>
          <View style={styles.infoCard}>
            <Text style={styles.infoCardTitle}>About Transit Pulse</Text>
            <Text style={styles.infoCardText}>
              Transit Pulse Tracker provides real-time updates for your selected
              route. Track buses, trains, and subways with live position updates
              and delay information.
            </Text>
          </View>

          <View style={styles.infoCard}>
            <Text style={styles.infoCardTitle}>How to Use</Text>
            <Text style={styles.infoCardText}>
              1. Select a transit route from the options above
            </Text>
            <Text style={styles.infoCardText}>
              2. Press "Start Tracking" to begin tracking your journey
            </Text>
            <Text style={styles.infoCardText}>
              3. Receive updates about arrival times and any delays
            </Text>
            <Text style={styles.infoCardText}>
              4. Press "Stop Tracking" when you've reached your destination
            </Text>
          </View>
        </View>

        {/* Footer with extra space for scrolling */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>Transit Pulse © 2025</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#1B2838",
  },
  scrollView: {
    flex: 1,
  },
  scrollViewContent: {
    flexGrow: 1,
  },
  header: {
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: "#2A3F5F",
  },
  title: {
    fontSize: 20,
    fontWeight: "bold",
    color: "#FFFFFF",
    textAlign: "center",
  },
  glContainer: {
    height: 300, // Fixed height instead of flex: 1 to make it scrollable
    overflow: "hidden",
  },
  gl: {
    flex: 1,
  },
  controlsContainer: {
    padding: 16,
    backgroundColor: "#2A3F5F",
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    marginTop: -20,
  },
  routeSelector: {
    flexDirection: "row",
    marginBottom: 16,
  },
  routeButton: {
    padding: 12,
    marginRight: 12,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
    minWidth: 100,
  },
  activeRouteButton: {
    borderWidth: 2,
    borderColor: "#FFFFFF",
  },
  routeIcon: {
    fontSize: 24,
    marginBottom: 4,
  },
  routeNumber: {
    fontSize: 18,
    fontWeight: "bold",
    color: "#FFFFFF",
  },
  routeDestination: {
    fontSize: 14,
    color: "#FFFFFF",
  },
  routeInfo: {
    backgroundColor: "#1B2838",
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
  },
  routeInfoText: {
    fontSize: 16,
    color: "#FFFFFF",
    marginBottom: 4,
  },
  timeInfo: {
    marginTop: 8,
    padding: 8,
    backgroundColor: "#2A3F5F",
    borderRadius: 4,
  },
  timeText: {
    fontSize: 18,
    fontWeight: "bold",
    color: "#FFFFFF",
  },
  delayText: {
    fontSize: 14,
    color: "#F44336",
    fontWeight: "bold",
    marginTop: 4,
  },
  actionButtons: {
    flexDirection: "row",
    justifyContent: "center",
  },
  startButton: {
    backgroundColor: "#4CAF50",
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    minWidth: 200,
    alignItems: "center",
  },
  stopButton: {
    backgroundColor: "#F44336",
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    minWidth: 200,
    alignItems: "center",
  },
  buttonText: {
    fontSize: 16,
    fontWeight: "bold",
    color: "#FFFFFF",
  },
  // New styles for additional content
  infoSection: {
    padding: 16,
    backgroundColor: "#1B2838",
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "bold",
    color: "#FFFFFF",
    marginBottom: 12,
    textAlign: "center",
  },
  infoCard: {
    backgroundColor: "#2A3F5F",
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
  },
  infoCardTitle: {
    fontSize: 16,
    fontWeight: "bold",
    color: "#FFFFFF",
    marginBottom: 8,
  },
  infoCardText: {
    fontSize: 14,
    color: "#CCCCCC",
    marginBottom: 6,
    lineHeight: 20,
  },
  footer: {
    padding: 20,
    alignItems: "center",
    backgroundColor: "#0E1621",
  },
  footerText: {
    fontSize: 12,
    color: "#999999",
  },
});
