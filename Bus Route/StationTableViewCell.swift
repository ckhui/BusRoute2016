//
//  StationTableViewCell.swift
//  Bus Route
//
//  Created by ALLAN CHAI on 30/11/2016.
//  Copyright © 2016 Wherevership. All rights reserved.
//

import UIKit

class StationTableViewCell: UITableViewCell {
    @IBOutlet weak var stationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        stationLabel.textColor  = UIColor.dodgerBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
