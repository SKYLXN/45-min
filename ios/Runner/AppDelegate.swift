import Flutter
import UIKit
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up method channel for reminders using plugin registry
    if let registrar = self.registrar(forPlugin: "RemindersPlugin") {
      let remindersChannel = FlutterMethodChannel(
        name: "com.45min/reminders",
        binaryMessenger: registrar.messenger()
      )
      
      remindersChannel.setMethodCallHandler { [weak self] (call, result) in
        self?.handleRemindersMethodCall(call: call, result: result)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleRemindersMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "hasRemindersAccess":
      hasRemindersAccess(result: result)
    case "requestRemindersAccess":
      requestRemindersAccess(result: result)
    case "exportShoppingList":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      exportShoppingList(arguments: arguments, result: result)
    case "exportCategorizedShoppingList":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      exportCategorizedShoppingList(arguments: arguments, result: result)
    case "clearShoppingList":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      clearShoppingList(arguments: arguments, result: result)
    case "shoppingListExists":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      shoppingListExists(arguments: arguments, result: result)
    case "getShoppingListItemCount":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      getShoppingListItemCount(arguments: arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func hasRemindersAccess(result: @escaping FlutterResult) {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    result(status == .authorized)
  }
  
  private func requestRemindersAccess(result: @escaping FlutterResult) {
    eventStore.requestAccess(to: .reminder) { (granted, error) in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(granted)
        }
      }
    }
  }
  
  private func exportShoppingList(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let listTitle = arguments["listTitle"] as? String,
          let items = arguments["items"] as? [String] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
      return
    }
    
    let dueDate = arguments["dueDate"] as? String
    let dueDateObj = dueDate != nil ? ISO8601DateFormatter().date(from: dueDate!) : nil
    
    createReminderList(title: listTitle, items: items, dueDate: dueDateObj, result: result)
  }
  
  private func exportCategorizedShoppingList(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let listTitle = arguments["listTitle"] as? String,
          let categorizedItems = arguments["categorizedItems"] as? [String: [String]] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
      return
    }
    
    let dueDate = arguments["dueDate"] as? String
    let dueDateObj = dueDate != nil ? ISO8601DateFormatter().date(from: dueDate!) : nil
    
    // Flatten categorized items into a single list with category headers
    var allItems: [String] = []
    for (category, items) in categorizedItems {
      allItems.append("--- \(category) ---")
      allItems.append(contentsOf: items)
    }
    
    createReminderList(title: listTitle, items: allItems, dueDate: dueDateObj, result: result)
  }
  
  private func createReminderList(title: String, items: [String], dueDate: Date?, result: @escaping FlutterResult) {
    // Check permission first
    let status = EKEventStore.authorizationStatus(for: .reminder)
    guard status == .authorized else {
      result(FlutterError(code: "PERMISSION_DENIED", message: "Reminders access not granted", details: nil))
      return
    }
    
    do {
      // Find or create the shopping list calendar
      var shoppingCalendar = findReminderList(withTitle: title)
      
      if shoppingCalendar == nil {
        shoppingCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        shoppingCalendar!.title = title
        shoppingCalendar!.source = eventStore.defaultCalendarForNewReminders()?.source
        try eventStore.saveCalendar(shoppingCalendar!, commit: false)
      } else {
        // Clear existing reminders if list already exists
        let predicate = eventStore.predicateForReminders(in: [shoppingCalendar!])
        eventStore.fetchReminders(matching: predicate) { [weak self] (reminders) in
          guard let self = self, let reminders = reminders else { return }
          do {
            for reminder in reminders {
              try self.eventStore.remove(reminder, commit: false)
            }
          } catch {
            print("Error removing existing reminders: \(error)")
          }
        }
      }
      
      // Create reminders for each item
      for item in items {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = item
        reminder.calendar = shoppingCalendar
        reminder.dueDateComponents = dueDate != nil ? Calendar.current.dateComponents([.year, .month, .day], from: dueDate!) : nil
        try eventStore.save(reminder, commit: false)
      }
      
      // Commit all changes
      try eventStore.commit()
      result(true)
      
    } catch {
      result(FlutterError(code: "EXPORT_FAILED", message: "Failed to create reminders: \(error.localizedDescription)", details: nil))
    }
  }
  
  private func findReminderList(withTitle title: String) -> EKCalendar? {
    let calendars = eventStore.calendars(for: .reminder)
    return calendars.first { $0.title == title }
  }
  
  private func clearShoppingList(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let listTitle = arguments["listTitle"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing list title", details: nil))
      return
    }
    
    guard let calendar = findReminderList(withTitle: listTitle) else {
      result(true) // List doesn't exist, consider it cleared
      return
    }
    
    let predicate = eventStore.predicateForReminders(in: [calendar])
    eventStore.fetchReminders(matching: predicate) { [weak self] (reminders) in
      guard let self = self, let reminders = reminders else {
        DispatchQueue.main.async { result(false) }
        return
      }
      
      do {
        for reminder in reminders {
          try self.eventStore.remove(reminder, commit: false)
        }
        try self.eventStore.commit()
        DispatchQueue.main.async { result(true) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "CLEAR_FAILED", message: "Failed to clear list: \(error.localizedDescription)", details: nil))
        }
      }
    }
  }
  
  private func shoppingListExists(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let listTitle = arguments["listTitle"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing list title", details: nil))
      return
    }
    
    let exists = findReminderList(withTitle: listTitle) != nil
    result(exists)
  }
  
  private func getShoppingListItemCount(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let listTitle = arguments["listTitle"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing list title", details: nil))
      return
    }
    
    guard let calendar = findReminderList(withTitle: listTitle) else {
      result(0)
      return
    }
    
    let predicate = eventStore.predicateForReminders(in: [calendar])
    eventStore.fetchReminders(matching: predicate) { (reminders) in
      DispatchQueue.main.async {
        result(reminders?.count ?? 0)
      }
    }
  }
}
