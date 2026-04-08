import { Component, inject } from '@angular/core';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../shared/services/auth.service';

@Component({
  selector: 'app-login-page',
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './login-page.component.html',
  styleUrl: './login-page.component.css'
})
export class LoginPageComponent {
  private fb = inject(FormBuilder);
  private router = inject(Router);
  private auth = inject(AuthService);

  loginForm: FormGroup;
  errorMessage: string = '';

  constructor() {
    this.loginForm = this.fb.group({
      usuario: ['', Validators.required],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  onSubmit() {
    if (this.loginForm.valid) {
      const { usuario, password } = this.loginForm.value;
      if (usuario === 'admin' && password === 'admin123') {
        this.auth.login();
        this.router.navigate(['/home']);
      } else {
        this.errorMessage = 'Credenciales incorrectas. Inténtalo de nuevo.';
      }
    }
  }
}
