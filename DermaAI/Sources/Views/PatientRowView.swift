//
//  PatientRowView.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//


import SwiftUI

struct PatientRowView: View {
    let patient: Patient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(patient.name)
                .font(.headline)
            Text("\(patient.medications.count) medications")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
