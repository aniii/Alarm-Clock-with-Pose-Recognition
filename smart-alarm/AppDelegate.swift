//
//  AppDelegate.swift
//  smart-alarm
//
//  Created by Peter Sun on 11/27/22.
//  Copyright © 2022 Peter Sun. All rights reserved.
//
import UIKit
import Foundation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    let alarmScheduler = AlarmModel.shared
    var alarmModel: Alarms = Alarms()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set notification delegate to be the class itself
        UNUserNotificationCenter.current().delegate = self

        window?.tintColor = UIColor.red
        
        return true
    }
   // this function is called when the timer goes off and the application is open
    func userNotificationCenter(_ center: UNUserNotificationCenter,
             willPresent notification: UNNotification,
             withCompletionHandler completionHandler:
                @escaping (UNNotificationPresentationOptions) -> Void) {
        //show an alert window
        let storageController = UIAlertController(title: "The ONLY to stop the alarm is to SMILE!", message: nil, preferredStyle: .alert)
        var isSnooze: Bool = false
        var soundName: String = ""
        var index: Int = -1
        
        let userInfo = notification.request.content.userInfo
            isSnooze = userInfo["snooze"] as! Bool
            soundName = userInfo["soundName"] as! String
            index = userInfo["index"] as! Int
        
        
        alarmScheduler.playSound(soundName)
        //schedule notification for snooze
        if isSnooze {
            let snoozeOption = UIAlertAction(title: "Snooze", style: .default) {
                (action:UIAlertAction)->Void in self.alarmScheduler.audioPlayer?.stop()
                Task {
                    await self.alarmScheduler.setNotificationForSnooze(snoozeMinute: 9, soundName: soundName, index: index)
                }
            }
            storageController.addAction(snoozeOption)
        }
        let stopOption = UIAlertAction(title: "OK", style: .default) {
            //(action:UIAlertAction)->Void in self.audioPlayer?.stop()
            (action:UIAlertAction)->Void in
            AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate)
            self.alarmModel = Alarms()
            self.alarmModel.alarms[index].onSnooze = false
            /////////////////////////
            /// ADD Video UI HERE!!!
            /// /////////////////////
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let mainVC = storyboard.instantiateViewController(withIdentifier: "Yoga") as? YogaPoseViewController
            self.window?.visibleViewController?.present(mainVC!, animated: true, completion: nil)
            
        }
        
        storageController.addAction(stopOption)
        window?.visibleViewController?.navigationController?.present(storageController, animated: true, completion: nil)

       // Don't alert the user for other types.
       completionHandler(UNNotificationPresentationOptions(rawValue: 0))
    }
    //called when the timer goes off and the application is in the background
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                didReceive response: UNNotificationResponse,
                withCompletionHandler completionHandler:
                   @escaping () -> Void) {
        var index: Int = -1
        var soundName: String = ""
        let userInfo = response.notification.request.content.userInfo
        soundName = userInfo["soundName"] as! String
        index = userInfo["index"] as! Int
        
        self.alarmModel = Alarms()
        self.alarmModel.alarms[index].onSnooze = false
        if response.actionIdentifier == Constants.snoozeIdentifier {
            Task {
                await alarmScheduler.setNotificationForSnooze(snoozeMinute: 9, soundName: soundName, index: index)
            }
            self.alarmModel.alarms[index].onSnooze = true
        }
        completionHandler()
    }
    
    func requestAuthorization(
        options: UNAuthorizationOptions = [],
        completionHandler: @escaping (Bool, Error?) -> Void
    ) {
        print(options.rawValue)
    }
    

    //UIApplicationDelegate protocol
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//        audioPlayer?.pause()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        audioPlayer?.play()
        Task {
            await alarmScheduler.checkNotification()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    



}

