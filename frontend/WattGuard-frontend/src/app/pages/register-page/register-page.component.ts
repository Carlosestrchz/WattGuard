import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';

@Component({
  selector: 'app-register-page',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './register-page.component.html',
  styleUrl: './register-page.component.css'
})
export class RegisterPageComponent {
  private fb = inject(FormBuilder);
  private router = inject(Router);

  registerForm: FormGroup;
  successMessage: string = '';
  errorMessage: string = '';

  constructor() {
    this.registerForm = this.fb.group({
      usuario: ['', Validators.required],
      correo: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  onSubmit() {
    if (this.registerForm.valid) {
      const { usuario, correo, password } = this.registerForm.value;
      localStorage.setItem('wattguardRegisteredUser', JSON.stringify({ usuario, correo, password }));
      this.successMessage = 'Registro exitoso. Redirigiendo al login...';
      this.errorMessage = '';
      this.registerForm.disable();
      setTimeout(() => {
        this.registerForm.enable();
        this.router.navigate(['/login']);
      }, 2200);
    } else {
      this.registerForm.markAllAsTouched();
      this.errorMessage = 'Por favor completa todos los campos correctamente.';
      this.successMessage = '';
    }
  }
}
