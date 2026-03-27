import tkinter as tk
from tkinter import filedialog
import time
import os
import numpy as np
import matplotlib.pyplot as plt
#from google.colab import files

import serial

import cv2
file_written = False
# Screen definitions


# Set this to match your actual COM port
ARDUINO_PORT = 'COM3'
BAUD_RATE = 9600

def create_welcome_screen():
    for widget in root.winfo_children():
        widget.destroy()

    welcome_frame = tk.Frame(root, bg="#F0F8FF")
    welcome_frame.pack(fill=tk.BOTH, expand=True)

    welcome_label = tk.Label(welcome_frame, text="Welcome to the System", font=("Arial", 16, "bold"), bg="#F0F8FF", fg="#2E8B57")
    welcome_label.pack(pady=20)

    start_button = tk.Button(welcome_frame, text="Start", command=create_load_fpga_screen, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    start_button.pack(pady=20)

    window_number_label = tk.Label(welcome_frame, text="1", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)

def create_load_fpga_screen():
    for widget in root.winfo_children():
        widget.destroy()

    load_fpga_frame = tk.Frame(root, bg="#F0F8FF")
    load_fpga_frame.pack(fill=tk.BOTH, expand=True)

    load_fpga_label = tk.Label(load_fpga_frame, text="Power UP", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    load_fpga_label.pack(pady=10)

    instructions = """
    Turn ON the board and wait for LED 1 to lit.
    If LED 1 is not lit in 1 minute press on PROG button in Board. 
    After LED1 is lit press on Continue.
    """
 #   instr_label = tk.Label(load_fpga_frame, text=instructions, font=("Arial", 12), bg="#F0F8FF", justify="left")
 #   instr_label.pack(pady=10)

    def open_fpga_instructions():
        os.startfile("instructions_fpga.txt")  # Instructions for loading the FPGA in a text file

 #   instructions_button = tk.Button(load_fpga_frame, text="Instructions", command=open_fpga_instructions, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
 #   instructions_button.pack(pady=10)

    load_fpga_label = tk.Label(load_fpga_frame, text="Power ON the board then wait for LED 1 to be ON and then press on BTNL in the board.\nIf LED 1 is not lit in 1 minute press on PROG button in Board and wait for LED1 to lit again.\nAfter LED1 is lit press on Continue. ", font=("Arial", 12), bg="#F0F8FF", fg="#00008B")
    load_fpga_label.pack(pady=20)

    def confirm_fpga_loaded():
        load_fpga_frame.destroy()
        create_camera_question_screen()

    confirm_button = tk.Button(load_fpga_frame, text="Continue", command=confirm_fpga_loaded, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    confirm_button.pack(pady=20)

    window_number_label = tk.Label(load_fpga_frame, text="2", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)

def create_camera_question_screen():
    for widget in root.winfo_children():
        widget.destroy()

    camera_frame = tk.Frame(root, bg="#F0F8FF")
    camera_frame.pack(fill=tk.BOTH, expand=True)

    camera_question_label = tk.Label(camera_frame, text="Do you see the camera image on the screen?", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    camera_question_label.pack(pady=10)

    def proceed_if_camera_visible():
        camera_frame.destroy()
        create_image_count_screen()

    def wait_for_camera_confirmation():
        camera_question_label.config(text="Waiting for confirmation that the image is displayed...")
        root.update()

    confirm_camera_button = tk.Button(camera_frame, text="Yes, I see the image", command=proceed_if_camera_visible, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    confirm_camera_button.pack(pady=10)

    retry_camera_button = tk.Button(camera_frame, text="No, waiting", command=wait_for_camera_confirmation, font=("Arial", 12), bg="#FF6347", fg="white", relief=tk.RAISED)
    retry_camera_button.pack(pady=10)

    window_number_label = tk.Label(camera_frame, text="3", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)

def create_image_count_screen():
    for widget in root.winfo_children():
        widget.destroy()

    count_frame = tk.Frame(root, bg="#F0F8FF")
    count_frame.pack(fill=tk.BOTH, expand=True)

    count_label = tk.Label(count_frame, text="How many images would you like to capture? (1–2047)", font=("Arial", 14), bg="#F0F8FF")
    count_label.pack(pady=20)

    num_images_entry = tk.Entry(count_frame, font=("Arial", 12))
    num_images_entry.pack(pady=10)

    sw_instruction_label = tk.Label(count_frame, text="", font=("Arial", 12), fg="blue", bg="#F0F8FF")
    sw_instruction_label.pack(pady=10)

    error_label = tk.Label(count_frame, text="", font=("Arial", 12), fg="red", bg="#F0F8FF")
    error_label.pack()

    def set_num_images():
        try:
            num_images = int(num_images_entry.get())
            if not (1 <= num_images <= 2047):
                raise ValueError("Enter a number between 1 and 2047.")
            
            # Convert to 11-bit binary string
            bin_value = format(num_images, '011b')  # 11 bits for 0–2047

            # Map bits to switches SW15 to SW5 (MSB to LSB)
            switches = [f"SW{15 - i}" for i in range(11)]  # SW15 to SW5
            instructions = []

            for bit, sw in zip(bin_value, switches):
                state = "ON" if bit == '1' else "OFF"
                instructions.append(f"{sw}: {state} (ON means towards 7-segment)")

            instruction_text = "Set the switches as follows:\n" + "\n".join(instructions)
            sw_instruction_label.config(text=instruction_text)
            error_label.config(text="")  # Clear any previous error

        except ValueError:
            error_label.config(text="Please enter a valid number between 1 and 2047.")
            sw_instruction_label.config(text="")  # Clear instructions if error

    enter_button = tk.Button(count_frame, text="Enter", command=set_num_images, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    enter_button.pack(pady=20)

    confirm_button = tk.Button(count_frame, text="Continue", command=create_image_instructions_screen, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    confirm_button.pack(pady=20)

    window_number_label = tk.Label(count_frame, text="4", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)



def create_image_instructions_screen():
    for widget in root.winfo_children():
        widget.destroy()

    instructions_frame = tk.Frame(root, bg="#F0F8FF")
    instructions_frame.pack(fill=tk.BOTH, expand=True)

    instructions_label = tk.Label(instructions_frame, text="Instructions for Capturing the Image:", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    instructions_label.pack(pady=10)

    instructions_text = """
    1. Point the camera at the first mark.
    2. Adjust the red line using BTNC on the development board so that the red line is at the bottom part of the mark.
    3️. Capture the image using BTNR on the development board.
    If you wish to take the picture again, press BTND on the development board.
    """
    instructions_detail = tk.Label(instructions_frame, text=instructions_text, font=("Arial", 12), bg="#F0F8FF", justify="left")
    instructions_detail.pack(pady=10)

    def proceed_after_image_taken():
        instructions_frame.destroy()
        create_sw1_screen()

    proceed_button = tk.Button(instructions_frame, text="Continue", command=proceed_after_image_taken, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    proceed_button.pack(pady=20)

    window_number_label = tk.Label(instructions_frame, text="5", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)

def create_sw1_screen():
    for widget in root.winfo_children():
        widget.destroy()

    sw1_frame = tk.Frame(root, bg="#F0F8FF")
    sw1_frame.pack(fill=tk.BOTH, expand=True)

    sw1_label = tk.Label(sw1_frame, text="Config", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    sw1_label.pack(pady=10)

    sw1_instructions = """
                            1.Open PUTTY.
                            2.Select Srieal in connection type.
                            3.Select the correct COM of the board(from control panel) and config the Speed to be 9600.
                            4.In the left bar go to Logging.
                            5.In Session logging choose All session output.
                            6.Press on Browse and choose to file to be placed in the same directory as the gui direcotry.
                            7.Select the name of the file to be:putty.txt and press on Save.
                            8.Press on Open,
                            9.Place SW1 upwards towards the buttons on the development board.
                       """
    sw1_instr_label = tk.Label(sw1_frame, text=sw1_instructions, font=("Arial", 12), bg="#F0F8FF", justify="left")
    sw1_instr_label.pack(pady=10)

    def proceed_after_sw1():
        sw1_frame.destroy()
        create_vtis_screen()

    sw1_button = tk.Button(sw1_frame, text="Continue", command=proceed_after_sw1, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    sw1_button.pack(pady=20)

    window_number_label = tk.Label(sw1_frame, text="6", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)

def create_vtis_screen():
    for widget in root.winfo_children():
        widget.destroy()

    vtis_frame = tk.Frame(root, bg="#F0F8FF")
    vtis_frame.pack(fill=tk.BOTH, expand=True)

    vtis_label = tk.Label(vtis_frame, text="🔧 Run the VTIS 🔧", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    vtis_label.pack(pady=10)

    instructions = """
    Place SW2 upwards towards the buttons on the development board.
    Then wait for LED3 to be ON which indicates process is finished.
    ⏳ The process might take approximately 15 minutes.
    """
    instr_label = tk.Label(vtis_frame, text=instructions, font=("Arial", 12), bg="#F0F8FF", justify="left")
    instr_label.pack(pady=10)

    def check_vtis_status():
        def confirm_message():
            vtis_frame.destroy()
            create_generate_image_screen()

        def retry_process():
            vtis_label.config(text="Please make sure the VTIS process has finished and try again.")
            root.update()

        # חלון של שאלת כן/לא אם המשתמש ראה את הכיתוב
        message_box = tk.Toplevel(root)
        message_box.title("Confirmation")
        message_box.geometry("300x150")
        message_label = tk.Label(message_box, text="Did you see 'Processing finished.' in the Putty screen?", font=("Arial", 12))
        message_label.pack(pady=10)

        yes_button = tk.Button(message_box, text="Yes", command=confirm_message, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
        yes_button.pack(pady=5)

        no_button = tk.Button(message_box, text="No", command=retry_process, font=("Arial", 12), bg="#FF6347", fg="white", relief=tk.RAISED)
        no_button.pack(pady=5)

    confirm_button = tk.Button(vtis_frame, text="Continue", command=create_generate_image_screen, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    confirm_button.pack(pady=20)

    window_number_label = tk.Label(vtis_frame, text="7", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)
    
def create_generate_image_screen():
    
    

    

    def open_file_dialog():
        global file_path
        file_path = filedialog.askopenfilename(title="Select File", filetypes=(("Text files", "*.txt"), ("All files", "*.*")))
        if file_path:
            file_name_label.config(text=f"Selected file: {os.path.basename(file_path)}")
        else:
            file_name_label.config(text="No file selected.")

    def remove_first_and_last_line(file_path):
        with open(file_path, 'r') as file:
            lines = file.readlines()

        if len(lines) < 3:
            print("הקובץ קצר מדי – אין מספיק שורות למחיקה.")
            return

        new_lines = lines[1:-1]  # מחיקת שורה ראשונה ואחרונה

        with open(file_path, 'w') as file:
            file.writelines(new_lines)
        print("שורה ראשונה ואחרונה הוסרו.")
    
    
    def generate_image_from_data(file_path):
        width, height = 640, 480
        uploaded = {file_path: file_path}  # Example

        # Get the path of putty.txt specifically
        dat_file_path = uploaded.get(file_path)  # Use the correct key
        
        
        with open(dat_file_path, 'r') as file:
            lines = file.readlines()
        
        
        new_lines = lines[1:-1]  # מחיקת שורה ראשונה ואחרונה
        
        with open(dat_file_path, 'w') as file:
            file.writelines(new_lines)
        
        image_data = np.zeros((height, width, 3), dtype=np.uint8)

        with open(dat_file_path, "r") as file:
            data = file.readlines()

        for line in data:
            line = line.strip()  # Remove any trailing spaces/newlines
            if not line:  # Skip empty lines
                continue
            parts = line.split()  # Split the line into parts by spaces
            if len(parts) < 2:  # Ensure there's at least one part (the hex value)
                continue

            hex_value = parts[0]  # Get the hex value
            address = int(parts[1])  # Get the address

            if not hex_value.startswith("0x"):  # Skip if it's not a valid hex value
                continue

            try:
                hex_value = hex_value[2:]  # Remove "0x" prefix
                int_value = int(hex_value, 16)  # Convert the hex to an integer

                # Extract the 4-bit values for red, green, and blue
                r = (int_value >> 8) & 0x0F  # Extract red bits (bits 11-8)
                g = (int_value >> 4) & 0x0F  # Extract green bits (bits 7-4)
                b = int_value & 0x0F         # Extract blue bits (bits 3-0)

                # Normalize to the range 0-255 by multiplying by 17
                r = r * 17
                g = g * 17
                b = b * 17

                # Calculate row and column from the address
                row = address // width
                col = address % width

                # Check if the address is within valid bounds
                if row < height and col < width:
                    image_data[row, col] = (r, g, b)
                else:
                    print(f"Invalid address: {address} (row: {row}, col: {col})")

            except ValueError:
                print(f"Skipping invalid line: {line}")
                continue

        non_black_pixels = np.where(image_data != 0)
        min_row = np.min(non_black_pixels[0])
        max_row = np.max(non_black_pixels[0])
        min_col = np.min(non_black_pixels[1])
        max_col = np.max(non_black_pixels[1])

        cropped_image = image_data[min_row:max_row+1, min_col:max_col+1]

        plt.imshow(cropped_image)
        plt.axis('off')  # Hide axes
        plt.show()

        image_path = "cropped_image.jpeg"
        plt.imsave(image_path, cropped_image)


    for widget in root.winfo_children():
        widget.destroy()

    upload_frame = tk.Frame(root, bg="#F0F8FF")
    upload_frame.pack(fill=tk.BOTH, expand=True)

    upload_label = tk.Label(upload_frame, text="Upload the Text File Generated by Putty", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    upload_label.pack(pady=10)

    instructions = """
    Please upload the text file generated by Putty("putty.txt").
    Press the "Choose File" button and select the file from your computer.
    """
    instr_label = tk.Label(upload_frame, text=instructions, font=("Arial", 12), bg="#F0F8FF", justify="left")
    instr_label.pack(pady=10)

    choose_file_button = tk.Button(upload_frame, text="Choose File", command=open_file_dialog, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    choose_file_button.pack(pady=10)

    file_name_label = tk.Label(upload_frame, text="No file selected", font=("Arial", 12), bg="#F0F8FF", fg="green")
    file_name_label.pack(pady=10)

    generate_image_frame = tk.Frame(root, bg="#F0F8FF")
    generate_image_frame.pack(fill=tk.BOTH, expand=True)

    generate_image_label = tk.Label(generate_image_frame, text="Generate Image from .dat file", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    generate_image_label.pack(pady=10)

    # Create the button with lambda to pass file_path correctly
    generate_image_button = tk.Button(generate_image_frame, text="Generate Image", command=lambda: generate_image_from_data(file_path), font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    generate_image_button.pack(pady=20)
    
    generate_image_button = tk.Button(generate_image_frame, text="Continue", command=create_detect_music_char, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    generate_image_button.pack(pady=20)

    window_number_label = tk.Label(generate_image_frame, text="8", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)

def create_detect_music_char():

    def open_music_chars_file():
        os.startfile("music_chars_file.txt")  

    def save_to_file(note, filename="music_chars_file.txt"):
        global file_written
    
        if not file_written:
            with open(filename, "w") as file:
                file.write("")  
            file_written = True

        with open(filename, "a") as file:
            file.write(f"Detected Note: {note}\n")

    def open_file_dialog():
        global file_path
        file_path = filedialog.askopenfilename(title="Select File", filetypes=(("JPEG files", "*.jpeg"), ("All files", "*.*")))
        if file_path:
            file_name_label.config(text=f"Selected file: {os.path.basename(file_path)}")
        else:
            file_name_label.config(text="No file selected.")

    def find_and_filter_staff_lines(binary_image, max_lines=5, spacing_tolerance=0.6):
        projection = np.sum(binary_image, axis=1)
        threshold = 0.7 * np.max(projection)
        potential_lines = np.where(projection > threshold)[0]

        line_clusters = []
        current_cluster = [potential_lines[0]]
        for i in range(1, len(potential_lines)):
            if potential_lines[i] == potential_lines[i-1] + 1:
                current_cluster.append(potential_lines[i])
            else:
                line_clusters.append(current_cluster)
                current_cluster = [potential_lines[i]]
        line_clusters.append(current_cluster)

        line_positions = [int(np.mean(cluster)) for cluster in line_clusters]
        line_positions.sort()

        spacing_estimates = np.diff(line_positions)
        avg_spacing = np.median(spacing_estimates)

        filtered_lines = [line_positions[0]]
        for pos in line_positions[1:]:
            if pos - filtered_lines[-1] > spacing_tolerance * avg_spacing:
                filtered_lines.append(pos)
            if len(filtered_lines) == max_lines:
                break

        return filtered_lines

    def detect_red_line(image):
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        lower_red1 = np.array([0, 70, 50])
        upper_red1 = np.array([10, 255, 255])
        lower_red2 = np.array([170, 70, 50])
        upper_red2 = np.array([180, 255, 255])
        red_mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
        red_mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
        red_mask = cv2.bitwise_or(red_mask1, red_mask2)

        red_projection = np.sum(red_mask, axis=1)
        red_y = np.argmax(red_projection)

        if red_projection[red_y] > 50:
            return red_y
        else:
            return None

    def determine_note(note_center, staff_lines):
        staff_lines = sorted(staff_lines)
        note_names = ["F5", "E5", "D5", "C5", "B4", "A4", "G4", "F4", "E4", "D4", "C4", "B3", "A3", "G3"]

        if len(staff_lines) >= 2:
            avg_spacing = (staff_lines[-1] - staff_lines[0]) / (len(staff_lines) - 1)
            tolerance = avg_spacing / 8
        else:
            raise ValueError("At least 2 staff lines are required")

        if note_center < staff_lines[0]:
            steps_above = int((staff_lines[0] - note_center) / (avg_spacing / 2))
            return note_names[steps_above]

        for i in range(len(staff_lines) - 1):
            upper_line = staff_lines[i]
            lower_line = staff_lines[i + 1]

            if upper_line < note_center < lower_line:
                region_height = (lower_line - upper_line) / 2
                if note_center < upper_line + region_height:
                    return note_names[i * 2]
                else:
                    return note_names[i * 2 + 1]
            if abs(note_center - upper_line) <= tolerance:
                return note_names[i * 2 - 1]

        if note_center >= staff_lines[-1]:
            steps_below = int((note_center - staff_lines[-1]) / (avg_spacing / 2))
            return note_names[7 + steps_below]

        return None

    def detect_music_char(file_path):
        print(file_path)
        uploaded = {file_path: file_path}
        dat_file_path = uploaded.get(file_path)
        uploaded_filename = dat_file_path

        image = cv2.imread(uploaded_filename)
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        binary = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_MEAN_C,
                                     cv2.THRESH_BINARY_INV, 15, 2)

        staff_lines = find_and_filter_staff_lines(binary, max_lines=5)
        red_line_y = detect_red_line(image)

        if red_line_y is not None:
            note = determine_note(red_line_y, staff_lines)
            print(f"Detected Note: {note}")
            note_label.config(text=f"The music char is: {note}", font=("Arial", 30, "bold"), fg="blue")
            save_to_file(note)
            global global_detected_note
            global_detected_note = note
        else:
            note_label.config(text="Red line not detected", font=("Arial", 30, "bold"), fg="red")

    # GUI Setup
    for widget in root.winfo_children():
        widget.destroy()

    upload_frame = tk.Frame(root, bg="#F0F8FF")
    upload_frame.pack(fill=tk.BOTH, expand=True)

    upload_label = tk.Label(upload_frame, text="Upload the generated JPEG File", font=("Arial", 10, "bold"), bg="#F0F8FF", fg="#8B0000")
    upload_label.pack(pady=10)

    instructions = "Please upload the JPEG File generated by Putty"
    instr_label = tk.Label(upload_frame, text=instructions, font=("Arial", 10), bg="#F0F8FF", justify="left")
    instr_label.pack(pady=10)

    choose_file_button = tk.Button(upload_frame, text="Choose File", command=open_file_dialog, font=("Arial", 10), bg="#4682B4", fg="white", relief=tk.RAISED)
    choose_file_button.pack(pady=10)

    file_name_label = tk.Label(upload_frame, text="No file selected", font=("Arial", 10), bg="#F0F8FF", fg="green")
    file_name_label.pack(pady=10)

    generate_image_frame = tk.Frame(root, bg="#F0F8FF")
    generate_image_frame.pack(fill=tk.BOTH, expand=True)

    generate_image_label = tk.Label(generate_image_frame, text="Detect music char", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    generate_image_label.pack(pady=10)

    generate_image_button = tk.Button(generate_image_frame, text="Detect music char", command=lambda: detect_music_char(file_path), font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    generate_image_button.pack(pady=20)

    note_label = tk.Label(generate_image_frame, text="", font=("Arial", 30, "bold"), bg="#F0F8FF", fg="blue")
    note_label.pack(pady=20)

    instructions_button = tk.Button(generate_image_frame, text="music chars detected", command=open_music_chars_file, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    instructions_button.pack(pady=10)
    
    play_button = tk.Button(generate_image_frame, text="Play detected char", command=lambda: send_note(ser, global_detected_note), font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    play_button.pack(pady=10)
    
    generate_image_button_continue = tk.Button(generate_image_frame, text="Continue", command=create_sw4_window, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    generate_image_button_continue.pack(pady=20)
    
    window_number_label = tk.Label(generate_image_frame, text="9", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=9)

def create_sw4_window():
    for widget in root.winfo_children():
        widget.destroy()

    instructions_frame = tk.Frame(root, bg="#F0F8FF")
    instructions_frame.pack(fill=tk.BOTH, expand=True)

    instructions_label = tk.Label(instructions_frame, text="Move to next image or finish and play", font=("Arial", 14, "bold"), bg="#F0F8FF", fg="#8B0000")
    instructions_label.pack(pady=10)

    instructions_text = """
    1. Move SW4 to be ON.
    2. Move SW4 to be OFF.
    Note: ON means SW is towards Seven Segment. 
    If the number in the left seven segment(4 left digits) is bigger than the number in the right seven segment(4 right digits) press on Finsh Detection if not press on Continue to another image.
    """
    instructions_detail = tk.Label(instructions_frame, text=instructions_text, font=("Arial", 12), bg="#F0F8FF", justify="left")
    instructions_detail.pack(pady=10)

    proceed_button = tk.Button(instructions_frame, text="Continue to another image", command=create_image_instructions_screen, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    proceed_button.pack(pady=20)
    
    # כפתור להמשך
    generate_image_button_continue = tk.Button(instructions_frame, text="Finsh Detection", command=create_play_all_chars, font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    generate_image_button_continue.pack(pady=20)

    window_number_label = tk.Label(instructions_frame, text="10", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=10)


# Create the serial connection once and reuse it
def init_serial_connection():
    try:
        ser = serial.Serial(ARDUINO_PORT, BAUD_RATE, timeout=1)
        time.sleep(2)  # Wait for Arduino to reset
        return ser
    except serial.SerialException as e:
        print(f"Serial error: {e}")
        return None


        
def create_play_all_chars():    
    
    def send_note(ser, note):
        if ser and ser.is_open:
            message = note.strip() + '\n'
            ser.write(message.encode())
            print(f"Sent: {note}")
        else:
            print("Serial port not open.")
    
    
    def play_notes_from_file(file_path, ser):
        try:
            with open(file_path, "r") as file:
                for line in file:
                    if "Detected Note:" in line:
                        # Extract the note after "Detected Note:"
                        note = line.strip().split("Detected Note:")[-1].strip()
                        if note:
                            print(f"Sending note: {note}")
                            send_note(ser, note)
                            time.sleep(0.5)
        except Exception as e:
            print(f"Error reading or sending notes: {e}")

    def open_file_dialog():
        global file_path
        file_path = filedialog.askopenfilename(title="Select File", filetypes=(("txt files", "*.txt"), ("All files", "*.*")))
        if file_path:
            file_name_label.config(text=f"Selected file: {os.path.basename(file_path)}")
        else:
            file_name_label.config(text="No file selected.")
    
    
    for widget in root.winfo_children():
        widget.destroy()


    upload_frame = tk.Frame(root, bg="#F0F8FF")
    upload_frame.pack(fill=tk.BOTH, expand=True)

    upload_label = tk.Label(upload_frame, text="Upload the generated music(music_chars_file.txt).", font=("Arial", 10, "bold"), bg="#F0F8FF", fg="#8B0000")
    upload_label.pack(pady=10)

    welcome_frame = tk.Frame(upload_frame, bg="#F0F8FF")
    welcome_frame.pack(fill=tk.BOTH, expand=True)

    choose_file_button = tk.Button(welcome_frame, text="Choose File", command=open_file_dialog, font=("Arial", 10), bg="#4682B4", fg="white", relief=tk.RAISED)
    choose_file_button.pack(pady=10)

    # יצירת תווית להציג את שם הקובץ הנבחר
    file_name_label = tk.Label(welcome_frame, text="No file selected", font=("Arial", 10), bg="#F0F8FF", fg="green")
    file_name_label.pack(pady=10)

    
    play_button = tk.Button(welcome_frame, text="Play all detected char", command=lambda:play_notes_from_file(file_path,ser), font=("Arial", 12), bg="#4682B4", fg="white", relief=tk.RAISED)
    play_button.pack(pady=10)

    generate_image_button_continue = tk.Button(welcome_frame, text="Finish", command=create_finish_screen, font=("Arial", 12), bg="#32CD32", fg="white", relief=tk.RAISED)
    generate_image_button_continue.pack(pady=20)

    window_number_label = tk.Label(welcome_frame, text="11", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=11)

    
        
def create_finish_screen():    
    for widget in root.winfo_children():
        widget.destroy()

    welcome_frame = tk.Frame(root, bg="#F0F8FF")
    welcome_frame.pack(fill=tk.BOTH, expand=True)

    
    
   

    welcome_label = tk.Label(welcome_frame, text="Goodbye", font=("Arial", 16, "bold"), bg="#F0F8FF", fg="#2E8B57")
    welcome_label.pack(pady=20)

    window_number_label = tk.Label(welcome_frame, text="12", font=("Arial", 10), bg="#F0F8FF")
    window_number_label.pack(side=tk.BOTTOM, pady=12)
            
    



# Create the root window


# Create the main window (root window)
root = tk.Tk()
root.title("FPGA Camera and Image Capture")
root.geometry("600x800")  

root.configure(bg="#F0F8FF")

# Initialize the first screen (Welcome screen)
create_welcome_screen()

ser = init_serial_connection()

# Start the GUI loop
root.mainloop()
