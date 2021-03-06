//
//  InterestDashboardAnnouncementPresenting.swift
//  InterestUIKit
//
//  Created by Alex McGregor on 8/14/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformUIKit

public protocol InterestDashboardAnnouncementPresenting: AnyObject {
    var cellArrangement: [InterestAnnouncementCellType] { get }
    var cellCount: Int { get }
}
