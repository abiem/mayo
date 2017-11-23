//
//  MapViewExtension.swift
//  Mayo-ios-client
//
//  Created by abiem  on 5/25/17.
//  Copyright © 2017 abiem. All rights reserved.
//

import UIKit
import MapKit

extension MainViewController: MKMapViewDelegate {
    
    // used for custom viwes on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        
        guard !(annotation is MKUserLocation) else { return nil }
        
        // set annotation for current user
        if annotation is CustomCurrentUserTaskAnnotation {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "customCurrentUserTask")
            
            // if there is currently a task for the current user and
            // the index  is 0 for carousel
            // show focus annotation
            if self.carouselView.currentItemIndex == 0 {
                annotationView.image = UIImage(named: "currentUserMapFocusTaskIcon")
                annotationView.layer.zPosition = CGFloat(self.FOCUS_MAP_TASK_ANNOTATION_Z_INDEX)
            } else {
                // else show standard current user annotation
                annotationView.image = UIImage(named: "currentUserMapTaskIcon")
                annotationView.layer.zPosition = CGFloat(self.STANDARD_MAP_TASK_ANNOTATION_Z_INDEX)
            }
            
            return annotationView
        }
        
        if annotation is CustomUserMapAnnotation {
            
            
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "customUser")
            // get last updated time
            let customAnnotation = annotation as! CustomUserMapAnnotation
           annotationView.alpha = 0
        self.usersRef?.child(customAnnotation.userId!).child("UpdatedAt").observeSingleEvent(of: .value, with: { (snapshot) in
                if let updatedTimeString = snapshot.value as? String {
                    let currentTime = Date();
                    let updatedTime = DateStringFormatterHelper().convertStringToDate(datestring: updatedTimeString)
                    let timeDifference = currentTime.seconds(from: updatedTime)
                    annotationView.image  = self.getUserLocationImage(timeDifference)
                    UIView.animate(withDuration: 0.4, animations: {
                        annotationView.alpha = 1
                    })
                }
                
            })
            
            return annotationView
        }
        
        if annotation is CustomTaskMapAnnotation {
            
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "customTask")
            annotationView.image = UIImage(named: "mapTaskIcon")
            annotationView.layer.zPosition = CGFloat(self.STANDARD_MAP_TASK_ANNOTATION_Z_INDEX)
            
            return annotationView
        }
        
        if annotation is CustomFocusTaskMapAnnotation {
            
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "customFocusTask")
            annotationView.image = UIImage(named: "mapFocusTaskIcon")
            annotationView.layer.zPosition = CGFloat(self.FOCUS_MAP_TASK_ANNOTATION_Z_INDEX)
            
            
            return annotationView
        }
        
        
        if annotation is CustomFocusUserMapAnnotation {
            
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "customTask")
            annotationView.image = UIImage(named: "mapTaskIcon")
            annotationView.layer.zPosition = CGFloat(self.FOCUS_MAP_TASK_ANNOTATION_Z_INDEX)
            return annotationView
        }
        
        
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if view.annotation is MKUserLocation {
                // send user to front
                view.layer.zPosition = 2
            }
        }
    }
    
    // runs when an annotation is tapped on
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("annoation selected")
        
        if view.annotation is CustomUserMapAnnotation {
            // if its a custom user annotation
            // move center of map to the user
            print("custom annotation block hit")
            if let annotation = view.annotation {
                self.mapView.setCenter( annotation.coordinate, animated: true)
                // exit delegate method
                return
            }
        }
        //if the annotation is the current user task annotation
        if view.annotation is CustomCurrentUserTaskAnnotation {
            // move carousel to the current user's card
            if let annotation = view.annotation as? CustomCurrentUserTaskAnnotation {
                self.mapView.setCenter(annotation.coordinate, animated: true)
                
                if let index = annotation.currentCarouselIndex {
                    self.carouselView.scrollToItem(at: index, animated: true)
                }
                // exit delegate method
                return
            }
        }
        // if the annotation is a task
        if view.annotation is CustomTaskMapAnnotation {
            // move the carousel to the right task card
            
            if let annotation = view.annotation as? CustomTaskMapAnnotation {
                self.mapView.setCenter( annotation.coordinate, animated: true)
                if let index = annotation.currentCarouselIndex {
                    self.carouselView.scrollToItem(at: index, animated: true)
                }
                // exit delegate method
                return
            }
        }
    }
    func getUserLocationImage(_ time:Int) -> UIImage? {
        if time <= locationIconTime.first.rawValue {
            return #imageLiteral(resourceName: "greenDot")
        }
        else if time <= locationIconTime.second.rawValue {
            return #imageLiteral(resourceName: "greenDot")
        }
        else if time <= locationIconTime.third.rawValue {
            return #imageLiteral(resourceName: "greenDot")
        }
        else if time <= locationIconTime.fourth.rawValue {
            return #imageLiteral(resourceName: "greenDot")
        }
        else if time <= locationIconTime.fifth.rawValue {
            return #imageLiteral(resourceName: "greenDot")
        }
        else if time <= locationIconTime.sixth.rawValue {
            return #imageLiteral(resourceName: "greenDot")
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = TWOGradientCircleRenderer(overlay: overlay)
            return circleRenderer
        } else {
            return MKOverlayRenderer()
        }
    }
    
    func addRadiusCircle(location: CLLocation){
        self.mapView.delegate = self
        let circle = MKCircle(center: location.coordinate, radius: 200 as CLLocationDistance)
        self.mapView.add(circle)
    }
    
    func removeCircle() {
        self.mapView.overlays.forEach {
            if ($0 is MKCircle) {
                self.mapView.remove($0)
            }
        }
    }

}
