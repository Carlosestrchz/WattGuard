import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';

interface UserProfile {
  usuario: string;
  correo: string;
  password: string;
}

@Component({
  selector: 'app-profile-page',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './profile-page.component.html',
  styleUrl: './profile-page.component.css'
})
export class ProfilePageComponent {
  private fb = inject(FormBuilder);

  profileForm: FormGroup;
  successMessage: string = '';
  errorMessage: string = '';

  private currentUser: UserProfile = {
    usuario: 'admin',
    correo: 'admin@wattguard.com',
    password: 'admin123'
  };

  constructor() {
    this.loadProfile();

    this.profileForm = this.fb.group({
      usuario: [{ value: this.currentUser.usuario, disabled: true }],
      correo: [this.currentUser.correo, [Validators.required, Validators.email]],
      password: [this.currentUser.password, [Validators.required, Validators.minLength(6)]]
    });
  }

  private loadProfile() {
    const stored = localStorage.getItem('wattguardRegisteredUser');
    if (stored) {
      try {
        this.currentUser = JSON.parse(stored) as UserProfile;
      } catch {
        // keep default admin profile
      }
    }
  }

  onSubmit() {
    if (this.profileForm.valid) {
      const updatedProfile: UserProfile = {
        usuario: this.currentUser.usuario,
        correo: this.profileForm.get('correo')?.value,
        password: this.profileForm.get('password')?.value
      };

      localStorage.setItem('wattguardRegisteredUser', JSON.stringify(updatedProfile));
      this.successMessage = 'Perfil actualizado correctamente.';
      this.errorMessage = '';
      this.currentUser = updatedProfile;
    } else {
      this.errorMessage = 'Por favor completa el correo y la contraseña correctamente.';
      this.successMessage = '';
      this.profileForm.markAllAsTouched();
    }
  }
}
