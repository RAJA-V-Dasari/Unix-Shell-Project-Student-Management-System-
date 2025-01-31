#!/bin/bash

# Root directory for storing student data
students_dir="students"

# Function to initialize the directory structure
initialize_directories() {
    mkdir -p "$students_dir"
    branches=("CSE" "ECE" "EEE" "MECH")
    semesters=("1st_Sem" "2nd_Sem" "3rd_Sem" "4th_Sem" "5th_Sem" "6th_Sem" "7th_Sem" "8th_Sem")
    sections=("A.csv" "B.csv")

    for branch in "${branches[@]}"; do
        for semester in "${semesters[@]}"; do
            mkdir -p "$students_dir/$branch/$semester"
            for section in "${sections[@]}"; do
                file_path="$students_dir/$branch/$semester/$section"
                if [[ ! -f "$file_path" ]]; then
                    echo "Student ID,Name,section,Contact" > "$file_path"
                fi
            done
        done
    done
    echo "Directory structure initialized."
}
initialize_directories

# Global variables for branch, semester, and section
branch=""
semester=""
section=""
section_file=""

# Function to select branch, semester, and section once
select_branch_semester_section() {
    branch=$(zenity --list --title="Select Branch" --column="Branches" "CSE" "ECE" "EEE" "MECH")
    if [[ -z "$branch" ]]; then return 1; fi

    semester=$(zenity --list --title="Select Semester" --column="Semesters" "1st_Sem" "2nd_Sem" "3rd_Sem" "4th_Sem" "5th_Sem" "6th_Sem" "7th_Sem" "8th_Sem")
    if [[ -z "$semester" ]]; then return 1; fi

    section=$(zenity --list --title="Select Section" --column="Sections" "A" "B")
    if [[ -z "$section" ]]; then return 1; fi

    section_file="$students_dir/$branch/$semester/${section}.csv"
    echo "Selected: $branch $semester $section"
}



add_student() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    while true; do
        # Get student details without asking for section
        student_details=$(zenity --forms --title="Add Student" \
            --add-entry="Name" \
            --add-entry="Contact (10-digit number)" \
            --separator=",")
        if [[ $? -ne 0 ]]; then
            zenity --error --text="No student added."
            return
        fi

        IFS=',' read -r name contact <<< "$student_details"

        # Validation for empty fields
        if [[ -z "$name" || -z "$contact" ]]; then
            zenity --error --text="All fields are required. Please try again."
            continue
        fi

        # Validation for contact number
        if [[ ! "$contact" =~ ^[0-9]{10}$ ]]; then
            zenity --error --text="Contact must be a 10-digit number. Please try again."
            continue
        fi

        # Generate a new unique Student ID
        student_id=$(($(wc -l < "$section_file") - 1))
        echo "$student_id,$name,$section,$contact" >> "$section_file"
        zenity --info --text="Student '$name' added successfully with ID $student_id."
        break
    done
}





# Function to view students
view_students() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    student_records=$(tail -n +2 "$section_file")
    if [[ -z "$student_records" ]]; then
        zenity --info --text="No student records found."
    else
        zenity --text-info --title="Student Records" --filename="$section_file"
    fi
}



# Function to mark attendance
mark_attendance() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    attendance_file="${section_file%.csv}_attendance.csv"
    if [[ ! -f "$attendance_file" ]]; then
        echo "Student ID,Date,Time,Status" > "$attendance_file"
    fi

    current_date=$(date +%Y-%m-%d)
    current_time=$(date +%H:%M:%S)
    student_records=$(tail -n +2 "$section_file")

    if [[ -z "$student_records" ]]; then
        zenity --info --text="No students found to mark attendance."
        return
    fi

    while IFS=',' read -r student_id name section contact; do
        status=$(zenity --list --title="Mark Attendance" --radiolist \
            --column="Select" --column="Status" TRUE "Present" FALSE "Absent" \
            --text="Mark attendance for $name (ID: $student_id)")

        if [[ $? -ne 0 ]]; then
            zenity --error --text="Attendance marking canceled."
            return
        fi

        echo "$student_id,$current_date,$current_time,$status" >> "$attendance_file"
    done <<< "$student_records"

    zenity --info --text="Attendance marked successfully."
}

# Function to view attendance
view_attendance() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    attendance_file="${section_file%.csv}_attendance.csv"
    if [[ ! -f "$attendance_file" ]]; then
        zenity --info --text="No attendance records found."
        return
    fi

    attendance_records=$(tail -n +2 "$attendance_file")
    if [[ -z "$attendance_records" ]]; then
        zenity --info --text="No attendance records found."
    else
        zenity --text-info --title="Attendance Records" --filename="$attendance_file"
    fi
}

# Function to set subjects and credits for a specific branch and semester
set_subjects() {
    if [[ -z "$branch" || -z "$semester" ]]; then
        zenity --error --text="Please select a branch and semester first."
        return
    fi

    subjects_file="students/$branch/$semester/subjects.csv"

    # Prompt for subject names and credits
    subjects_and_credits=$(zenity --forms --title="Set Subjects and Credits" \
        --add-entry="Subject 1 Name" \
        --add-entry="Subject 1 Credits" \
        --add-entry="Subject 2 Name" \
        --add-entry="Subject 2 Credits" \
        --add-entry="Subject 3 Name" \
        --add-entry="Subject 3 Credits" \
        --add-entry="Subject 4 Name" \
        --add-entry="Subject 4 Credits" \
        --add-entry="Subject 5 Name" \
        --add-entry="Subject 5 Credits" \
        --add-entry="Subject 6 Name" \
        --add-entry="Subject 6 Credits" \
        --add-entry="Subject 7 Name" \
        --add-entry="Subject 7 Credits" \
        --add-entry="Subject 8 Name" \
        --add-entry="Subject 8 Credits" \
        --separator=",")

    if [[ $? -ne 0 || -z "$subjects_and_credits" ]]; then
        zenity --error --text="Subject names and credits are required."
        return
    fi

    IFS=',' read -r sub1_name sub1_credits sub2_name sub2_credits sub3_name sub3_credits sub4_name sub4_credits sub5_name sub5_credits sub6_name sub6_credits sub7_name sub7_credits sub8_name sub8_credits <<< "$subjects_and_credits"

    # Create the subjects file and write the subjects and credits
    mkdir -p "$(dirname "$subjects_file")" # Ensure directory exists
    echo "Subject,Credits" > "$subjects_file"
    echo "$sub1_name,$sub1_credits" >> "$subjects_file"
    echo "$sub2_name,$sub2_credits" >> "$subjects_file"
    echo "$sub3_name,$sub3_credits" >> "$subjects_file"
    echo "$sub4_name,$sub4_credits" >> "$subjects_file"
    echo "$sub5_name,$sub5_credits" >> "$subjects_file"
    echo "$sub6_name,$sub6_credits" >> "$subjects_file"
    echo "$sub7_name,$sub7_credits" >> "$subjects_file"
    echo "$sub8_name,$sub8_credits" >> "$subjects_file"

    # Update the marks file header
    marks_file="${section_file%.csv}_marks.csv"

    # Check if marks file exists, if not, create it
    if [[ ! -f "$marks_file" ]]; then
        echo "Student ID,Student Name,$sub1_name,$sub2_name,$sub3_name,$sub4_name,$sub5_name,$sub6_name,$sub7_name,$sub8_name" > "$marks_file"
    else
        # If the marks file exists, update the header with the new subjects
        temp_file=$(mktemp)
        tail -n +2 "$marks_file" > "$temp_file"  # Remove old data
        echo "Student ID,Student Name,$sub1_name,$sub2_name,$sub3_name,$sub4_name,$sub5_name,$sub6_name,$sub7_name,$sub8_name" > "$marks_file"
        cat "$temp_file" >> "$marks_file"  # Append the existing data without the header
        rm "$temp_file"  # Clean up temporary file
    fi

    zenity --info --text="Subjects and credits set successfully for $branch $semester and marks file header updated."
}


# Function to add marks for students
add_marks() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    marks_file="${section_file%.csv}_marks.csv"
    subjects_file="students/$branch/$semester/subjects.csv"

    # Check if subjects file exists, and read subjects and credits
    if [[ ! -f "$subjects_file" ]]; then
        zenity --error --text="Subjects have not been set for $branch $semester."
        return
    fi

    subjects_and_credits=$(cat "$subjects_file" | tail -n +2) # Skip header line
    IFS=$'\n' read -d '' -r -a subjects_array <<< "$subjects_and_credits"

    subject_names=()
    subject_credits=()

    for line in "${subjects_array[@]}"; do
        IFS=',' read -r subject_name credits <<< "$line"
        subject_names+=("$subject_name")
        subject_credits+=("$credits")
    done

    # Check if marks file exists, if not, create it
    if [[ ! -f "$marks_file" ]]; then
        echo "Student ID,Student Name,${subject_names[*]}" > "$marks_file"
    fi

    while true; do
        student_id=$(zenity --entry --title="Enter Student ID" --text="Enter Student ID:")

        if [[ -z "$student_id" ]]; then
            zenity --error --text="Student ID is required."
            continue
        fi

        # Fetch student name from the section file
        student_name=$(awk -F, -v id="$student_id" '$1 == id {print $2}' "$section_file")

        if [[ -z "$student_name" ]]; then
            zenity --error --text="Student ID $student_id not found in records."
            continue
        fi

        marks_details=$(zenity --forms --title="Add Marks for $student_name" \
            --add-entry="${subject_names[0]} Marks (0-100)" \
            --add-entry="${subject_names[1]} Marks (0-100)" \
            --add-entry="${subject_names[2]} Marks (0-100)" \
            --add-entry="${subject_names[3]} Marks (0-100)" \
            --add-entry="${subject_names[4]} Marks (0-100)" \
            --add-entry="${subject_names[5]} Marks (0-100)" \
            --add-entry="${subject_names[6]} Marks (0-100)" \
            --add-entry="${subject_names[7]} Marks (0-100)" \
            --separator=",")

        if [[ $? -ne 0 || -z "$marks_details" ]]; then
            zenity --error --text="Marks entry canceled."
            return
        fi

        IFS=',' read -r m1 m2 m3 m4 m5 m6 m7 m8 <<< "$marks_details"

        # Validation for marks (each should be between 0 and 100)
        for mark in "$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7" "$m8"; do
            if [[ ! "$mark" =~ ^[0-9]+$ || "$mark" -lt 0 || "$mark" -gt 100 ]]; then
                zenity --error --text="Marks must be a number between 0 and 100. Please try again."
                continue 2
            fi
        done

        # Save student data to marks file
        echo "$student_id,$student_name,$m1,$m2,$m3,$m4,$m5,$m6,$m7,$m8" >> "$marks_file"
        zenity --info --text="Marks added successfully for $student_name (ID: $student_id)."
        break
    done
}



view_marks() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    marks_file="${section_file%.csv}_marks.csv"

    if [[ ! -f "$marks_file" ]]; then
        zenity --error --text="No marks file found for this section."
        return
    fi

    zenity --text-info --title="Marks List" --filename="$marks_file" --width=600 --height=400
}


# Function to generate reports
generate_reports() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    report_file="students/$branch/$semester/report_$section.csv"

    # Read subjects dynamically from marks.csv (skipping header)
    IFS=',' read -ra subjects <<< "$(head -n 1 "${section_file%.csv}_marks.csv" | cut -d',' -f3-)"
    echo "Student ID,Name,Attendance Percentage,${subjects[*]},Total Marks,Average Marks,GPA" > "$report_file"

    # Read credits from subjects.csv (skipping header)
    declare -A credits
    while IFS=, read -r subject credit; do
        credits["$subject"]=$credit
    done < <(tail -n +2 students/$branch/$semester/subjects.csv)

    while IFS=, read -r student_id name section contact; do
        attendance_file="${section_file%.csv}_attendance.csv"
        marks_file="${section_file%.csv}_marks.csv"

        # Calculate attendance percentage
        if [[ -f $attendance_file ]]; then
            total_records=$(grep -c "^$student_id," "$attendance_file")
            present_records=$(grep -c "^$student_id,.*,Present" "$attendance_file")
            if (( total_records > 0 )); then
                attendance_percentage=$(echo "scale=2; ($present_records / $total_records) * 100" | bc)
            else
                attendance_percentage="0.00"
            fi
        else
            attendance_percentage="N/A"
        fi

        # Get subject marks and compute total, average, and GPA
        if [[ -f $marks_file ]]; then
            total_marks=0
            gpa_total=0
            credit_sum=0
            marks_list=()

            while IFS=, read -r id _ m1 m2 m3 m4 m5 m6 m7 m8; do
                if [[ "$id" == "$student_id" ]]; then
                    marks_list=("$m1" "$m2" "$m3" "$m4" "$m5" "$m6" "$m7" "$m8")

                    for i in "${!marks_list[@]}"; do
                        mark=${marks_list[$i]}
                        total_marks=$((total_marks + mark))
                        subject="${subjects[$i]}"
                        credit="${credits[$subject]:-0}"  # Default to 0 if no credit is found
                        if (( mark >= 90 )); then
                                 grade_point=10
                        elif (( mark >= 80 )); then
                                 grade_point=9
                        elif (( mark >= 70 )); then
                                 grade_point=8
                        elif (( mark >= 60 )); then
                                grade_point=7
                        elif (( mark >= 50 )); then
                                grade_point=6
                        elif (( mark >= 40 )); then
                                grade_point=5
                        else
                                grade_point=0
                        fi

                        if [[ "$credit" =~ ^[0-9]+$ ]]; then
                            gpa_total=$(echo "$gpa_total + ($grade_point * $credit)" | bc)
                            credit_sum=$(echo "$credit_sum + $credit" | bc)
                        fi
                    done
                fi
            done < <(tail -n +2 "$marks_file")

            # Calculate average marks
            if (( ${#marks_list[@]} > 0 )); then
                average_marks=$(echo "scale=2; $total_marks / ${#marks_list[@]}" | bc)
            else
                average_marks="N/A"
            fi
            # Calculate GPA
            if (( credit_sum > 0 )); then
                gpa=$(echo "scale=2; $gpa_total / $credit_sum" | bc)
            else
                gpa="N/A"
            fi
        else
            marks_list=("N/A" "N/A" "N/A" "N/A" "N/A" "N/A" "N/A" "N/A")
            total_marks="N/A"
            average_marks="N/A"
            gpa="N/A"
        fi

        # Join marks with commas for the final report
        marks_csv=$(IFS=,; echo "${marks_list[*]}")
        echo "$student_id,$name,$attendance_percentage,$marks_csv,$total_marks,$average_marks,$gpa" >> "$report_file"
    done < <(tail -n +2 "$section_file")

    zenity --info --text="Report generated at $report_file."
}


view_report() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    report_file="students/$branch/$semester/report_$section.csv"

    if [[ ! -f "$report_file" ]]; then
        zenity --info --text="No report found for the selected section."
        return
    fi

    report_records=$(tail -n +2 "$report_file")
    if [[ -z "$report_records" ]]; then
        zenity --info --text="The report is empty."
    else
        zenity --text-info --title="Generated Report" --filename="$report_file" --width=800 --height=600
    fi
}


get_top_students() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    marks_file="${section_file%.csv}_marks.csv"
    if [[ ! -f "$marks_file" ]]; then
        zenity --error --text="No marks records found for the selected section."
        return
    fi

    marks_records=$(tail -n +2 "$marks_file")
    if [[ -z "$marks_records" ]]; then
        zenity --info --text="No marks records found in the section."
        return
    fi

    declare -A student_totals
    while IFS=',' read -r student_id sub1 sub2 sub3 sub4 sub5 sub6 sub7 sub8; do
        total_marks=$((sub1 + sub2 + sub3 + sub4 + sub5 + sub6 + sub7 + sub8))
        student_totals["$student_id"]=$total_marks
    done <<< "$marks_records"

    top_students=$(for student_id in "${!student_totals[@]}"; do
        echo "$student_id,${student_totals[$student_id]}"
    done | sort -t',' -k2 -nr | head -n 5)

    output="Rank\tID\tTotal Marks\n"
    rank=1
    while IFS=',' read -r student_id total_marks; do
        output+="$rank\t$student_id\t$total_marks\n"
        ((rank++))
    done <<< "$top_students"

    echo -e "$output" | zenity --text-info \
        --title="Top 5 Students by Total Marks" \
        --width=600 --height=400 \
        --filename=/dev/stdin
}




# Function to get the current selection label
get_selection_label() {
    echo "${branch:-NIL}, ${semester:-NIL}, ${section:-NIL}"
}

# Function to view the set subjects and credits for a specific branch and semester
view_subjects() {
    if [[ -z "$branch" || -z "$semester" ]]; then
        zenity --error --text="Please select a branch and semester first."
        return
    fi

    subjects_file="students/$branch/$semester/subjects.csv"

    # Check if the subjects file exists
    if [[ ! -f "$subjects_file" ]]; then
        zenity --error --text="No subjects set for $branch $semester."
        return
    fi

    # Read the subjects and credits from the file
    subjects_and_credits=$(cat "$subjects_file" | tail -n +2) # Skip the header line

    # Check if there are any subjects listed
    if [[ -z "$subjects_and_credits" ]]; then
        zenity --error --text="No subjects found for $branch $semester."
        return
    fi

    # Format the output to display subject names and credits
    subject_list=$(echo "$subjects_and_credits" | while IFS=',' read -r subject credits; do
        echo "Subject: $subject, Credits: $credits"
    done)

    # Display the list of subjects
    zenity --info --title="Subjects for $branch $semester" --text="$subject_list"
}


delete_student() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    student_id=$(zenity --entry --title="Enter Student ID" --text="Enter Student ID to delete:")

    if [[ -z "$student_id" ]]; then
        zenity --error --text="Student ID is required."
        return
    fi

    # Remove student record from section file
    temp_file=$(mktemp)
    awk -F, -v id="$student_id" '$1 != id' "$section_file" > "$temp_file"
    mv "$temp_file" "$section_file"

    zenity --info --text="Student ID $student_id deleted successfully."
}


delete_attendance() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    student_id=$(zenity --entry --title="Enter Student ID" --text="Enter Student ID to delete attendance:")

    if [[ -z "$student_id" ]]; then
        zenity --error --text="Student ID is required."
        return
    fi

    attendance_file="${section_file%.csv}_attendance.csv"

    # Remove attendance record for the student
    temp_file=$(mktemp)
    awk -F, -v id="$student_id" '$1 != id' "$attendance_file" > "$temp_file"
    mv "$temp_file" "$attendance_file"

    zenity --info --text="Attendance for Student ID $student_id deleted successfully."
}

delete_marks() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    student_id=$(zenity --entry --title="Enter Student ID" --text="Enter Student ID to delete marks:")

    if [[ -z "$student_id" ]]; then
        zenity --error --text="Student ID is required."
        return
    fi

    marks_file="${section_file%.csv}_marks.csv"

    # Remove marks record for the student
    temp_file=$(mktemp)
    awk -F, -v id="$student_id" '$1 != id' "$marks_file" > "$temp_file"
    mv "$temp_file" "$marks_file"

    zenity --info --text="Marks for Student ID $student_id deleted successfully."
}
delete_report() {
    if [[ -z "$branch" || -z "$semester" || -z "$section" ]]; then
        zenity --error --text="Please select a branch, semester, and section first."
        return
    fi

    report_file="students/$branch/$semester/report_$section.csv"

    if [[ ! -f "$report_file" ]]; then
        zenity --error --text="No report found for this section."
        return
    fi

    rm "$report_file"

    zenity --info --text="Report for $branch $semester $section deleted successfully."
}



# Update the main menu to include the "View Subjects" option
main_menu() {
    while true; do
        # Get the current selection label
        current_selection=$(get_selection_label)

        # Show main menu options
        action=$(zenity --list --title="Main Menu" \
            --text="Current Selection: Branch: $current_selection" \
            --column="Options" \
            "Select Branch, Semester, and Section" \
            "Add Student" \
            "View Students" \
            "Mark Attendance" \
            "View Attendance" \
            "Add Marks" \
            "View Marks" \
            "Top 5 Students" \
            "Generate Reports" \
            "View Report" \
            "Set Subjects" \
            "View Subjects" \
            "Delete Student" \
            "Delete Attendance" \
            "Delete Marks" \
            "Delete Report" \
            "Exit")

        # Check Zenity exit status
        if [[ $? -ne 0 ]]; then
            # If Cancel or Close button is clicked, exit the app
            exit 0
        fi

        case $action in
            "Select Branch, Semester, and Section") select_branch_semester_section ;;
            "Add Student") add_student ;;
            "View Students") view_students ;;
            "Mark Attendance") mark_attendance ;;
            "View Attendance") view_attendance ;;
            "Add Marks") add_marks ;;
            "View Marks") view_marks ;;
            "Top 5 Students") get_top_students ;;
            "Generate Reports") generate_reports ;;
            "View Report") view_report ;;
            "Set Subjects") set_subjects ;;
            "View Subjects") view_subjects ;;
             "Delete Student") delete_student ;;
        "Delete Attendance")
            delete_attendance
            ;;
        "Delete Marks")
            delete_marks
            ;;
        "Delete Report")
            delete_report
            ;;
            "Exit") exit 0 ;;
            *) zenity --error --text="Invalid option. Please try again." ;;
        esac
    done
}

main_menu
