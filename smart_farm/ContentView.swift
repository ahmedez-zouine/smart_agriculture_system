import SwiftUI
import Charts

// MARK: - Models
struct SensorReading: Identifiable {
    let id = UUID()
    let timestamp: Date
    let temperature: Double
    let humidity: Double
    let pH: Double
    let soilTemperature: Double
}

struct SensorLimits {
    static let temperature = (min: 20.0, max: 30.0)
    static let humidity = (min: 50.0, max: 80.0)
    static let pH = (min: 6.0, max: 8.0)
    static let soilTemperature = (min: 25.0, max: 35.0)
}

// MARK: - View Models
class DashboardViewModel: ObservableObject {
    @Published var readings: [SensorReading] = []
    @Published var currentReading: SensorReading?
    @Published var notifications: [String] = []
    @Published var selectedTimeRange: TimeRange = .hour
    
    enum TimeRange: String, CaseIterable {
        case hour = "1 Hour"
        case day = "24 Hours"
        case week = "1 Week"
    }
    
    init() {
        generateInitialData()
        startSimulation()
    }
    
    private func generateInitialData() {
        let now = Date()
        for i in 0..<10 {
            let reading = SensorReading(
                timestamp: now.addingTimeInterval(Double(-i * 30)),
                temperature: Double.random(in: 22...28),
                humidity: Double.random(in: 55...75),
                pH: Double.random(in: 6.5...7),
                soilTemperature: Double.random(in: 20...30)
            )
            readings.append(reading)
        }
        currentReading = readings.first
    }
    
    private func startSimulation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.generateNewReading()
        }
    }
    
    private func generateNewReading() {
        let lastReading = currentReading ?? readings.last ?? SensorReading(
            timestamp: Date(),
            temperature: 25.0,
            humidity: 65.0,
            pH: 7.0,
            soilTemperature: 25.0
        )
        
        let newReading = SensorReading(
            timestamp: Date(),
            temperature: max(20, min(30, lastReading.temperature + Double.random(in: -0.5...0.5))),
            humidity: max(50, min(80, lastReading.humidity + Double.random(in: -1.0...1.0))),
            pH: max(6.0, min(8.0, lastReading.pH + Double.random(in: -0.1...0.1))),
            soilTemperature: max(20, min(30, lastReading.soilTemperature + Double.random(in: -0.3...0.3)))
        )
        
        DispatchQueue.main.async {
            self.currentReading = newReading
            self.readings.insert(newReading, at: 0)
            
            if self.readings.count > 20 {
                self.readings.removeLast()
            }
            
            self.checkLimits(newReading)
        }
    }
    
    private func checkLimits(_ reading: SensorReading) {
        if reading.temperature < SensorLimits.temperature.min ||
            reading.temperature > SensorLimits.temperature.max {
            addNotification("Temperature out of range: \(String(format: "%.1f°C", reading.temperature))")
        }
        
        if reading.humidity < SensorLimits.humidity.min ||
            reading.humidity > SensorLimits.humidity.max {
            addNotification("Humidity out of range: \(String(format: "%.1f%%", reading.humidity))")
        }
        
        if reading.pH < SensorLimits.pH.min ||
            reading.pH > SensorLimits.pH.max {
            addNotification("pH out of range: \(String(format: "%.1f", reading.pH))")
        }
        
        if reading.soilTemperature < SensorLimits.soilTemperature.min ||
            reading.soilTemperature > SensorLimits.soilTemperature.max {
            addNotification("Soil Temperature out of range: \(String(format: "%.1f°C", reading.soilTemperature))")
        }
    }
    
    private func addNotification(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .shortened)
        notifications.append("[\(timestamp)] \(message)")
        if notifications.count > 5 {
            notifications.removeFirst()
        }
    }
}

// MARK: - Views
struct CustomNavigationBar: View {
    var body: some View {
        ZStack {
            Color.theme.primary
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                    Text("")
                        .font(.title3.bold())
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.title2)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal)
            }
            .padding(.top, 8)
        }
        .frame(height: 60)
    }
}

struct SensorCard: View {
    let title: String
    let value: Double
    let unit: String
    let sensorId: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            Text("\(String(format: "%.1f", value))\(unit)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text("Sensor ID: \(sensorId)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct SensorChart: View {
    let readings: [SensorReading]
    @Binding var selectedTimeRange: DashboardViewModel.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Sensor Readings")
                    .font(.headline)
                Spacer()
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(DashboardViewModel.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Chart {
                ForEach(readings) { reading in
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Temperature", reading.temperature)
                    )
                    .foregroundStyle(Color.theme.temperature)
                    
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Humidity", reading.humidity)
                    )
                    .foregroundStyle(Color.theme.humidity)
                    
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("pH", reading.pH)
                    )
                    .foregroundStyle(Color.theme.ph)
                    
                    LineMark(
                        x: .value("Time", reading.timestamp),
                        y: .value("Soil Temp", reading.soilTemperature)
                    )
                    .foregroundStyle(Color.theme.soilTemp)
                }
            }
            .frame(height: 250)
            
            HStack(spacing: 16) {
                LegendItem(color: Color.theme.temperature, label: "Temperature")
                LegendItem(color: Color.theme.humidity, label: "Humidity")
                LegendItem(color: Color.theme.ph, label: "pH")
                LegendItem(color: Color.theme.soilTemp, label: "Soil Temp")
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NotificationView: View {
    let notifications: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.red)
                Text("Recent Alerts")
                    .font(.headline)
                Spacer()
            }
            
            if notifications.isEmpty {
                Text("No alerts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(notifications, id: \.self) { notification in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text(notification)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar()
            
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        if let reading = viewModel.currentReading {
                            SensorCard(
                                title: "Temperature",
                                value: reading.temperature,
                                unit: "°C",
                                sensorId: "TEMP001",
                                icon: "thermometer",
                                color: Color.theme.temperature
                            )
                            
                            SensorCard(
                                title: "Humidity",
                                value: reading.humidity,
                                unit: "%",
                                sensorId: "HUM001",
                                icon: "humidity.fill",
                                color: Color.theme.humidity
                            )
                            
                            SensorCard(
                                title: "pH Level",
                                value: reading.pH,
                                unit: "",
                                sensorId: "PH001",
                                icon: "drop.fill",
                                color: Color.theme.ph
                            )
                            
                            SensorCard(
                                title: "Soil Temperature",
                                value: reading.soilTemperature,
                                unit: "°C",
                                sensorId: "ST001",
                                icon: "thermometer.sun.fill",
                                color: Color.theme.soilTemp
                            )
                        }
                    }
                    
                    SensorChart(readings: viewModel.readings, selectedTimeRange: $viewModel.selectedTimeRange)
                    
                    NotificationView(notifications: viewModel.notifications)
                }
                .padding()
            }
            .background(Color.theme.background)
        }
        .edgesIgnoringSafeArea(.top)
    }
}

// MARK: - Theme
extension Color {
    static let theme = Theme()
}

struct Theme {
    let primary = Color(red: 44/255, green: 62/255, blue: 80/255)
    let background = Color(red: 245/255, green: 246/255, blue: 250/255)
    let cardBackground = Color.white
    
    let temperature = Color.orange
    let humidity = Color.blue
    let ph = Color.purple
    let soilTemp = Color.green
}

#Preview {
    ContentView()
}
