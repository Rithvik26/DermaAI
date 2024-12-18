//
//  AddMedicationView.swift
//  DermaAI
//
//  Created by Rithvik Golthi on 12/14/24.
//


import SwiftUI

struct AddMedicationView: View {
    @Binding var medication: Medication
    @Binding var medications: [Medication]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Medication Name", text: $medication.name)
                TextField("Dosage", text: $medication.dosage)
                TextField("Frequency", text: $medication.frequency)
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        medications.append(medication)
                        medication = Medication(name: "", dosage: "", frequency: "")
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}